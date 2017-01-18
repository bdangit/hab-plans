pkg_name=couchbase
pkg_origin=bdangit
pkg_version='4.5.1'
pkg_description="$(cat << EOF
  Couchbase Server is an open source, distributed, NoSQL document-oriented
  database. It exposes a fast key-value store with managed cache for
  submillisecond data operations, purpose-built indexers for fast queries and
  a query engine for executing SQL-like queries. For mobile and Internet of
  Things environments Couchbase Lite runs natively on-device and manages
  synchronization to Couchbase Server.
EOF
)"
pkg_maintainer='Ben Dang <me@bdang.it>'
# license ref: http://developer.couchbase.com/open-source-projects
pkg_license=('Apache-2.0')
pkg_upstream_url="https://github.com/couchbase/manifest"
pkg_source="https://github.com/couchbase/manifest.git"
pkg_shasum="nosum"
pkg_expose=(8081 8092 8093 8094 11210)

pkg_deps=(
  bdangit/icu56
  bdangit/v8
  core/busybox
  core/curl
  core/erlang16
  core/glibc
  core/gcc-libs
  core/libevent
  core/openssl
  core/python2
  core/snappy
  core/zlib
)
pkg_build_deps=(
  core/findutils
  core/grep
  core/repo
  core/cacerts
  core/cmake
  core/flatbuffers
  core/gcc
  core/git
  core/gnupg
  core/make
  core/ncurses
  core/patchelf
  core/sed
)
pkg_bin_dirs=(bin)

do_begin() {
  if [ -f /lib64/ld-linux-x86-64.so.2 ]
  then
    pushd /lib64 > /dev/null
    unlink ld-linux-x86-64.so.2
    popd > /dev/null
  fi
}

do_download() {
  export PYTHONPATH
  PYTHONPATH="$(pkg_path_for core/python2)"
  build_line "Setting PYTHONPATH=$PYTHONPATH"

  build_line "Setting up certs"
  certs="$(pkg_path_for core/cacerts)/ssl/certs/cacert.pem"
  export GIT_SSL_CAINFO="$certs"
  export SSL_CERT_FILE="$certs"

  build_line "Setting up git: username, email and other options"
  git config --global user.email "dev@null.sh"
  git config --global user.name "devnull"
  git config --global color.ui true
  git config --global core.autocrlf false
  git config --global core.filemode false

  mkdir -p "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname" > /dev/null

  build_line "Initializing the couchbase repo"
  repo init -u "$pkg_source" --manifest-name="released/$pkg_version.xml"

  build_line "Syncing the couchbase repo"
  repo sync

  build_line "Making sure it is really unmodified"
  repo forall -vc "git reset --hard"

  popd > /dev/null
}

do_verify() {
  return 0
}

do_clean() {
  return 0
}

do_unpack() {
  return 0
}

do_prepare() {
  debug "Create link for /lib/ld-linux-x86-64.so.2 to make included 'go' happy"
  pushd "/lib64" > /dev/null
  ln -s "$(hab pkg path core/glibc)/lib/ld-linux-x86-64.so.2"
  popd > /dev/null
}

do_build() {
  export LD_LIBRARY_PATH="$pkg_prefix/lib:$LD_RUN_PATH"
  build_line "Setting LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

  export CC
  CC=$(pkg_path_for core/gcc)/bin/gcc
  build_line "Setting CC=$CC"

  export CXX
  CXX=$(pkg_path_for core/gcc)/bin/g++
  build_line "Setting CXX=$CXX"

  GLIBC_DIR=$(pkg_path_for core/glibc)
  OPENSSL_DIR=$(pkg_path_for core/openssl)
  LIBEVENT_DIR=$(pkg_path_for core/libevent)
  CURL_DIR=$(pkg_path_for core/curl)
  ICU_DIR=$(pkg_path_for bdangit/icu56)
  SNAPPY_DIR=$(pkg_path_for core/snappy)
  FLATBUFFERS_DIR=$(pkg_path_for core/flatbuffers)
  V8_DIR=$(pkg_path_for bdangit/v8)
  ZLIB_DIR=$(pkg_path_for core/zlib)
  export EXTRA_CMAKE_OPTIONS="\
    -DCMAKE_VERBOSE_MAKEFILE=$DEBUG \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DDL_LIBRARY=${GLIBC_DIR}/lib/libdl.so \
    -DOPENSSL_SSL_LIBRARY=${OPENSSL_DIR}/lib/libssl.so \
    -DOPENSSL_CRYPT_LIBRARY=${OPENSSL_DIR}/lib/libcrypto.so \
    -DOPENSSL_INCLUDE_DIR=${OPENSSL_DIR}/include \
    -DLIBEVENT_CORE_LIB=${LIBEVENT_DIR}/lib/libevent_core.so \
    -DLIBEVENT_THREAD_LIB=${LIBEVENT_DIR}/lib/libevent_pthreads.so \
    -DLIBEVENT_EXTRA_LIB=${LIBEVENT_DIR}/lib/libevent_extra.so \
    -DLIBEVENT_INCLUDE_DIR=${LIBEVENT_DIR}/include \
    -DCURL_LIBRARIES=${CURL_DIR}/lib/libcurl.so \
    -DCURL_INCLUDE_DIR=${CURL_DIR}/include \
    -DICU_LIBRARIES='${ICU_DIR}/lib/libicudata.so;${ICU_DIR}/lib/libicui18n.so;${ICU_DIR}/lib/libicuio.so;${ICU_DIR}/lib/libicutu.so;${ICU_DIR}/lib/libicuuc.so' \
    -DICU_INCLUDE_DIR=${ICU_DIR}/include \
    -DSNAPPY_LIBRARIES=${SNAPPY_DIR}/lib/libsnappy.so \
    -DSNAPPY_INCLUDE_DIR=${SNAPPY_DIR}/include \
    -DFLATC=${FLATBUFFERS_DIR}/bin/flatc \
    -DFLATBUFFERS_INCLUDE_DIR=${FLATBUFFERS_DIR}/include \
    -DV8_INCLUDE_DIR=${V8_DIR} \
    -DV8_SHAREDLIB=${V8_DIR}/lib/libv8.so \
    -DV8_PLATFORMLIB=${V8_DIR}/lib/libv8_libplatform.so \
    -DV8_BASELIB=${V8_DIR}/lib/libv8_libbase.so \
    -DZ_LIBRARIES=${ZLIB_DIR}/lib/libz.so"
  build_line "Setting EXTRA_CMAKE_OPTIONS=$EXTRA_CMAKE_OPTIONS"

  make clean

  build_line "Fixing CMakelists.txts to ensure full paths to libraries"
  fix_list=(
    .
    couchbase-cli
    couchbase-examples
    couchdb
    couchstore
    ep-engine
    forestdb
    geocouch
    googletest
    memcached
    moxi
    ns_server
    platform
    query-ui
    sigar
    subjson
    tlm
  )
  for f in "${fix_list[@]}";
  do
    debug "...$f/CMakeLists.txt"
    hab pkg exec core/sed sed -i '/CMAKE_MINIMUM_REQUIRED\s*(VERSION 2.*)/Ia CMAKE_POLICY(SET CMP0060 NEW)' "$f/CMakeLists.txt"
  done

  build_line "Fixing 'moxi' to get core/zlib"
  sed -i 's/ZLIB z/ZLIB ${Z_LIBRARIES}/' moxi/CMakeLists.txt

  build_line "Lets build it! This could take awhile."
  make PREFIX="$pkg_prefix" \
       EXTRA_CMAKE_OPTIONS="$EXTRA_CMAKE_OPTIONS" \
       PRODUCT_VERSION="$pkg_version"
}

do_check() {
  make test
}

do_install() {
  # NOTE: CMAKE takes care of installation in the build phase
  build_line "Fixing interpreters"
  _fix_interpreter_in_path "$pkg_prefix/lib/python" core/busybox bin/env
  _fix_interpreter_in_path "$pkg_prefix/bin" core/busybox bin/bash
  _fix_interpreter_in_path "$pkg_prefix/bin" core/busybox bin/sh
  _fix_interpreter_in_path "$pkg_prefix/bin" core/busybox bin/env
  _fix_interpreter_in_path "$pkg_prefix/bin" core/python2 bin/python
}

do_end() {
  pushd /lib64 > /dev/null
  unlink ld-linux-x86-64.so.2
  popd > /dev/null
}

# private #
_fix_interpreter_in_path() {
  local path=$1
  local pkg=$2
  local int=$3

  find "$path" -type f \
    -exec grep -Iq . {} \; \
    -exec sh -c 'head -n 1 "$1" | grep -q "$2"' _ {} "$int" \; \
    -exec sh -c 'echo "$1"' _ {} \; > /tmp/fix_interpreter_in_path_list

  grep -v '^ *#' < /tmp/fix_interpreter_in_path_list | while IFS= read -r line
  do
    fix_interpreter "$line" "$pkg" "$int"
  done
  rm -rf /tmp/fix_interpreter_in_path_list
}
