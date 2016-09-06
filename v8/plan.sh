pkg_origin=bdangit
pkg_name=v8
pkg_version='3.23.6'
pkg_description=""
pkg_upstream_url="https://github.com/v8/v8"
pkg_license=('Apache 2.0')
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_source="https://chromium.googlesource.com/v8/v8.git"
pkg_shasum="nosum"
pkg_filename="$pkg_name"
pkg_deps=(
  core/python2
  core/coreutils
)
pkg_build_deps=(
  core/curl
  core/make
  core/openssl
  core/git
  core/cacerts
  core/subversion
  core/gcc
)
pkg_bin_dirs=(bin)

do_download() {
  certs="$(pkg_path_for core/cacerts)/ssl/certs/cacert.pem"
  export GIT_SSL_CAINFO="$certs"
  export SSL_CERT_FILE="$certs"

  if [[ -d "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version" || -d "$HAB_CACHE_SRC_PATH/$pkg_name" ]]; then
    build_line "Found previous v8 and will destroy it."
    ## TODO: remove
    # return 0
    rm -rf "${HAB_CACHE_SRC_PATH:?}/$pkg_name/"
    rm -rf "${HAB_CACHE_SRC_PATH:?}/$pkg_name-$pkg_version/"
    rm -rf "${HAB_CACHE_SRC_PATH:?}/.gclient"
  fi

  build_line "Setting up git: username, email and other options"
  git config --global user.email "humans@habitat.sh"
  git config --global user.name "hab"
  git config --global color.ui true
  git config --global core.autocrlf false
  git config --global core.filemode false

  build_line "Setting up build environment for processing v8 hooks"
  _build_environment

  pushd "$HAB_CACHE_SRC_PATH" > /dev/null

  build_line "Setting up Google's Depot Tools"
  depot_tools_path=$(pwd)/depot_tools
  export PATH="$depot_tools_path":"$PATH"

  if [[ -d "depot_tools" ]]; then
    build_line "Found previous depot_tools and will destroy it."
    rm -rf "$depot_tools_path"
  fi
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  rm -rf "$depot_tools_path"/.git

  build_line "Fix interpreter for 'bin/env'"
  find "$depot_tools_path" -type f -executable \
    -exec sh -c 'file -i "$1" | grep -q "plain; charset=us-ascii"' _ {} \; \
    -exec sh -c 'head -n 1 "$1" | grep -q "bin/env"' _ {} \; \
    -exec sh -c 'echo "$1"' _ {} \; > /tmp/fix_list
  find "$depot_tools_path" -type f -executable \
    -exec sh -c 'file -i "$1" | grep -q "x-shellscript; charset=us-ascii"' _ {} \; \
    -exec sh -c 'head -n 1 "$1" | grep -q "bin/env"' _ {} \; \
    -exec sh -c 'echo "$1"' _ {} \; >> /tmp/fix_list
  grep -v '^ *#' < /tmp/fix_list | while IFS= read -r line
  do
    fix_interpreter "$line" core/coreutils bin/env
  done

  build_line "Enable verbose mode for gclient"
  sed -i 's/gclient\.py" "\$@"/gclient\.py" "\$@" "--verbose"/' "$depot_tools_path/gclient"

  attach
  build_line "Fetching v8 ... this could take awhile"
  fetch v8

  build_line "Checkout 'tags/$pkg_version'"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_name" > /dev/null
  git checkout tags/"$pkg_version"
  popd

  build_line "Move to $HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version"
  mv "$HAB_CACHE_SRC_PATH/$pkg_name" "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version"
  popd
}

do_unpack() {
  return 0
}

do_verify() {
  # TODO: get a way to verify a downlaoded git
  return 0
}

do_clean() {
  # Do not delete expanded src since we don't have a tar.gz
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
  make
}

do_install() {
  attach
  pushd "$HAB_CACHE_SRC_PATH/$pkg_name-$pkg_version" > /dev/null
  make install
  popd
}
#  return 0
  # mkdir -p "$pkg_prefix"/bin
  # install -m 0755 "$HAB_CACHE_SRC_PATH"/"$pkg_name" "$pkg_prefix"/bin/"$pkg_name"
  #
  # # fix shebang in `repo`
  # PYTHONPATH="$(pkg_path_for core/python2)"
  # sed -i "s#/usr/bin/env python#$PYTHONPATH/bin/python#" "$pkg_prefix"/bin/"$pkg_name"
# }
