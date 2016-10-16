pkg_origin=bdangit
pkg_name=v8
pkg_version='5.6.39'
pkg_description=""
pkg_upstream_url="https://github.com/v8/v8"
pkg_license=('Apache 2.0')
pkg_maintainer='Ben Dang <me@bdang.it>'
# pkg_source="https://github.com/$pkg_name/$pkg_name/archive/$pkg_version.tar.gz"
# pkg_shasum="05cce97d83e35852fe31491df3c4f286e47984bb7445bd4ea1e243de93da8889"
pkg_source="https://chromium.googlesource.com/v8/v8.git"
pkg_shasum="nosum"

pkg_deps=(
  core/python2
  core/coreutils
  core/bash
  core/glibc
  core/gcc-libs
)
pkg_build_deps=(
  core/patchelf
  core/curl
  core/make
  core/openssl
  core/git
  core/cacerts
  core/subversion
  core/gcc
  core/diffutils
  core/ninja
)
pkg_bin_dirs=(bin)

do_download() {
  # return 0

  certs="$(pkg_path_for core/cacerts)/ssl/certs/cacert.pem"
  export GIT_SSL_CAINFO="$certs"
  export SSL_CERT_FILE="$certs"

  if [[ -d "$HAB_CACHE_SRC_PATH/$pkg_filename" || -d "$HAB_CACHE_SRC_PATH/$pkg_name" ]]; then
    build_line "Found previous v8 and will destroy it."
    rm -rf "${HAB_CACHE_SRC_PATH:?}/$pkg_name"
    rm -rf "${HAB_CACHE_SRC_PATH:?}/$pkg_filename"
    rm -rf "${HAB_CACHE_SRC_PATH:?}/.gclient"
  fi

  build_line "Setting up git: username, email and other options"
  git config --global user.email "dev@null.sh"
  git config --global user.name "devnull"
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

  build_line "Fix interpreter for 'bin/env' in depot_tools"
  fix_interpreter_in_path "$depot_tools_path" core/coreutils bin/env

  build_line "Enable verbose mode for gclient"
  sed -i 's/gclient\.py" "\$@"/gclient\.py" "\$@" "--verbose"/' "$depot_tools_path/gclient"

  build_line "Fetching v8 ... this could take awhile"
  fetch v8

  rm -rf "${HAB_CACHE_SRC_PATH:?}/$pkg_dirname"
  mv "$HAB_CACHE_SRC_PATH/v8" "$HAB_CACHE_SRC_PATH/$pkg_dirname"

  popd > /dev/null
}

do_unpack() {
  return 0
}

do_verify() {
  return 0
}

do_clean() {
  return 0
}

do_prepare() {
  # return 0

  build_line "Checkout 'tags/$pkg_version'"
  git checkout "tags/$pkg_version"

  build_line "Fix interpreter for 'bin/env' in v8/build"
  fix_interpreter_in_path "build" core/coreutils bin/env

  build_line "Fix interpreter for 'bin/sh' in v8/build"
  fix_interpreter_in_path "build" core/bash bin/sh

  build_line "Fix interpreter for 'bin/env' in v8/tools"
  fix_interpreter_in_path "tools" core/coreutils bin/env

  build_line "Fix interpreter for 'bin/sh' in v8/tools"
  fix_interpreter_in_path "tools" core/bash bin/sh

  build_line "Fix interpreter for 'bin/sh' in v8/gypfiles"
  fix_interpreter_in_path "gypfiles" core/coreutils bin/env

  build_line "Patching included binaries in v8"
  binaries=(
    './buildtools/linux64/gn'
    './buildtools/linux64/clang-format'
  )
  export LD_RUN_PATH
  LD_RUN_PATH="${LD_RUN_PATH}:$(pkg_path_for core/gcc-libs)/lib"
  for binary in gn clang-format;
  do
    patchelf --interpreter "$(pkg_path_for core/glibc)/lib/ld-linux-x86-64.so.2" \
             --set-rpath "${LD_RUN_PATH}" \
             "./buildtools/linux64/$binary"
  done
}

do_build() {
  CC=$(pkg_path_for core/gcc)/bin/gcc
  export CC
  build_line "Setting CC=$CC"

  CXX=$(pkg_path_for core/gcc)/bin/g++
  export CXX
  build_line "Setting CXX=$CXX"

  export LD_LIBRARY_PATH
  LD_LIBRARY_PATH="$(pkg_path_for gcc)/lib"
  build_line "Setting LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

  tools/dev/v8gen.py -vv x64.release -- linux_use_bundled_binutils=false
  ninja -C out/gn.x64.release
}

do_install() {
  attach
}

fix_interpreter_in_path() {
  local path=$1
  local pkg=$2
  local int=$3

  find "$path" -type f -executable \
    -exec sh -c 'file -i "$1" | egrep -q "(plain|x-shellscript); charset=us-ascii"' _ {} \; \
    -exec sh -c 'head -n 1 "$1" | grep -q "$int"' _ {} \; \
    -exec sh -c 'echo "$1"' _ {} \; > /tmp/fix_interpreter_in_path_list
  grep -v '^ *#' < /tmp/fix_interpreter_in_path_list | while IFS= read -r line
  do
    fix_interpreter "$line" "$pkg" "$int"
  done
  rm -rf /tmp/fix_interpreter_in_path_list
}
