pkg_origin=bdangit
pkg_name=couchbase
pkg_version='4.5.1'
pkg_description='Couchbase open source edition'
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_license=('couchbase opensource edition')
pkg_upstream_url="http://www.couchbase.com/nosql-databases/downloads"
pkg_source="https://github.com/couchbase/manifest.git"
pkg_shasum="noshasum"
pkg_deps=(
  core/curl
  core/erlang
  core/glibc
  core/icu
  core/libevent
  core/ncurses
  core/openssl/1.0.2j/20160926152543
  core/python
  core/snappy
  bdangit/flatbuffers
  bdangit/v8
  # core/zlib/1.2.8/20161015000012
)
pkg_build_deps=(
  core/repo
  core/cacerts
  core/cmake
  core/gcc
  core/git
  core/gnupg
  core/make
  core/patchelf
)
pkg_bin_dirs=(bin)

do_download() {
  export GIT_SSL_CAINFO
  GIT_SSL_CAINFO="$(pkg_path_for core/cacerts)/ssl/certs/cacert.pem"
  build_line "Setting GIT_SSL_CAINFO=$GIT_SSL_CAINFO"

  export SSL_CERT_FILE="$GIT_SSL_CAINFO"
  build_line "Setting SSL_CERT_FILE=$SSL_CERT_FILE"

  export PYTHONPATH
  PYTHONPATH="$(pkg_path_for core/python)"
  build_line "Setting PYTHONPATH=$PYTHONPATH"

  build_line "Setting up git: username, email and other options"
  git config --global user.email "dev@null.com"
  git config --global user.name "devnull"
  git config --global color.ui false
  git config --global core.autocrlf true

  mkdir -p "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version" > /dev/null
  repo init -u "$pkg_source" --manifest-name="released/$pkg_version.xml"
  repo sync
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
  export CC
  CC=$(pkg_path_for core/gcc)/bin/gcc
  build_line "Setting CC=$CC"

  export CXX
  CXX=$(pkg_path_for core/gcc)/bin/g++
  build_line "Setting CXX=$CXX"

  OPENSSL_DIR=$(pkg_path_for core/openssl)

  LIBEVENT_DIR=$(pkg_path_for core/libevent)

  CURL_DIR=$(pkg_path_for core/curl)

  ICU_DIR=$(pkg_path_for core/icu)

  SNAPPY_DIR=$(pkg_path_for core/snappy)

  FLATBUFFERS_DIR=$(pkg_path_for bdangit/flatbuffers)

  V8_DIR=$(pkg_path_for bdangit/v8)

  #BREAKPAD_DIR=$(pkg_path_for bdangit/breakpad)

  export EXTRA_CMAKE_OPTIONS="-DOPENSSL_LIBRARIES=${OPENSSL_DIR}/lib \
                              -DOPENSSL_INCLUDE_DIR=${OPENSSL_DIR}/include \
                              -DLIBEVENT_CORE_LIB=${LIBEVENT_DIR}/lib \
                              -DLIBEVENT_INCLUDE_DIR=${LIBEVENT_DIR}/include \
                              -DLIBEVENT_THREAD_LIB=${LIBEVENT_DIR}/lib \
                              -DLIBEVENT_EXTRA_LIB=${LIBEVENT_DIR}/lib \
                              -DCURL_LIBRARIES=${CURL_DIR}/lib \
                              -DCURL_INCLUDE_DIR=${CURL_DIR}/include \
                              -DICU_LIBRARIES=${ICU_DIR}/lib \
                              -DICU_INCLUDE_DIR=${ICU_DIR}/include \
                              -DSNAPPY_LIBRARIES=${SNAPPY_DIR}/lib \
                              -DSNAPPY_INCLUDE_DIR=${SNAPPY_DIR}/include \
                              -DFLATC=${FLATBUFFERS_DIR}/bin \
                              -DFLATBUFFERS_INCLUDE_DIR=${FLATBUFFERS_DIR}/include \
                              -DV8_LIBRARIES=${V8_DIR}/lib \
                              -DV8_INCLUDE_DIR=${V8_DIR}/include"

  make PREFIX="$pkg_prefix" EXTRA_CMAKE_OPTIONS="$EXTRA_CMAKE_OPTIONS"
}
