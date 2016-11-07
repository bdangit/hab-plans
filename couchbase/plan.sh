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

pkg_deps=(
  core/glibc
  core/gcc-libs
  core/icu
  core/libevent
  core/openssl
  core/snappy
  bdangit/v8
)
pkg_build_deps=(
  core/erlang
  core/flatbuffers
  core/ncurses
  core/python2
  core/curl
  core/repo
  core/cacerts
  core/cmake
  core/gcc
  core/git
  core/gnupg
  core/make
  core/patchelf
  core/vim
)
pkg_bin_dirs=(bin)

do_download() {
  export PYTHONPATH
  PYTHONPATH="$(pkg_path_for core/python2)"
  build_line "Setting PYTHONPATH=$PYTHONPATH"

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

  build_line "initializing the couchbase repo"
  repo init -u "$pkg_source" --manifest-name="released/$pkg_version.xml"

  build_line "syncing the couchbase repo"
  repo sync

  build_line "making sure its really unmodified"
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
  ICU_DIR=$(pkg_path_for core/icu)
  SNAPPY_DIR=$(pkg_path_for core/snappy)
  FLATBUFFERS_DIR=$(pkg_path_for core/flatbuffers)
  V8_DIR=$(pkg_path_for bdangit/v8)

  export EXTRA_CMAKE_OPTIONS="\
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_PREFIX=$pkg_prefix \
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
    -DV8_BASELIB=${V8_DIR}/lib/libv8_libbase.so"

  make clean

  build_line "Fixing some CMakelists.txt -- make sure to link full paths to libraries"
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
    build_line "...$f/CMakeLists.txt"
    sed -i '/CMAKE_MINIMUM_REQUIRED\s*(VERSION 2.*)/Ia CMAKE_POLICY(SET CMP0060 NEW)' "$f/CMakeLists.txt"
  done

  make PREFIX="$pkg_prefix" \
       EXTRA_CMAKE_OPTIONS="$EXTRA_CMAKE_OPTIONS" \
       PRODUCT_VERSION="$pkg_version"
}
