pkg_origin=bdangit
pkg_name=couchbase
pkg_version='4.1.1'
pkg_description='Couchbase open source edition'
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_license=('couchbase opensource edition')
pkg_upstream_url="http://www.couchbase.com/nosql-databases/downloads"
pkg_source="https://github.com/couchbase/manifest.git"
pkg_shasum="no sha"
pkg_deps=(
  core/curl
  core/erlang
  core/glibc
  core/icu
  core/libevent
  core/ncurses
  core/openssl
  core/python
  core/snappy
)
pkg_build_deps=(
  bdangit/repo
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
  GIT_SSL_CAINFO="$(pkg_path_for core/cacerts)/ssl/certs/cacert.pem"
  export GIT_SSL_CAINFO
  build_line "Setting GIT_SSL_CAINFO=$GIT_SSL_CAINFO"

  export SSL_CERT_FILE="$GIT_SSL_CAINFO"
  build_line "Setting SSL_CERT_FILE=$SSL_CERT_FILE"

  PYTHONPATH="$(pkg_path_for core/python)"
  export PYTHONPATH
  build_line "Setting PYTHONPATH=$PYTHONPATH"

  build_line "Setting up git: username, email and other options"
  git config --global user.email "humans@habitat.sh"
  git config --global user.name "hab"
  git config --global color.ui false
  git config --global core.autocrlf true

  mkdir -p "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version"
  repo init -u "$pkg_source" --manifest-name="released/$pkg_version.xml"
  repo sync
  popd
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
  CC=$(pkg_path_for core/gcc)/bin/gcc
  export CC
  build_line "Setting CC=$CC"

  CXX=$(pkg_path_for core/gcc)/bin/g++
  export CXX
  build_line "Setting CXX=$CXX"

  make PREFIX="$pkg_prefix"
}
