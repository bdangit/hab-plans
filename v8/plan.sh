pkg_name=v8
pkg_origin=bdangit
pkg_version='5.6.134'
pkg_description="$(cat << EOF
  V8 is Google\'s open source high-performance JavaScript engine, written in
  C++ and used in Google Chrome, the open source browser from Google. It
  implements ECMAScript as specified in ECMA-262, and runs on Windows 7 or
  later, Mac OS X 10.5+, and Linux systems that use IA-32, ARM or MIPS
  processors. V8 can run standalone, or can be embedded into any C++
  application.
EOF
)"
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_license=('Apache-2.0')
pkg_upstream_url="https://github.com/v8/v8"
pkg_source="https://chromium.googlesource.com/v8/v8.git"
pkg_shasum="nosum"

pkg_deps=(
  core/coreutils
  core/gcc-libs
  core/glibc
)

pkg_build_deps=(
  core/binutils
  core/cacerts
  core/curl
  core/gcc
  core/git
  core/glib
  core/make
  core/openssl
  core/patchelf
  core/pcre
  core/python2
  core/pkg-config
  core/vim
)

pkg_bin_dirs=(bin)
pkg_lib_dirs=(lib)
pkg_include_dirs=(include)

V8_OUTPUTDIR=out.gn/x64.release

do_download() {
  certs="$(pkg_path_for core/cacerts)/ssl/certs/cacert.pem"
  export GIT_SSL_CAINFO="$certs"
  export SSL_CERT_FILE="$certs"

  build_line "Setting up git: username, email and other options"
  git config --global user.email "dev@null.sh"
  git config --global user.name "devnull"
  git config --global color.ui true
  git config --global core.autocrlf false
  git config --global core.filemode false

  build_line "Setting up build environment for processing v8 hooks"
  _build_environment

  build_line "Setting up Google's Depot Tools"
  _setup_depot_tools

  pushd "$HAB_CACHE_SRC_PATH" > /dev/null

  if [[ -d "$HAB_CACHE_SRC_PATH/$pkg_dirname/.git" ]]; then
    build_line "Found previous v8, attempting to re-use it"

    build_line "Uncheckout any modified files ..."
    for p in "." "build" "buildtools" "tools" "tools/clang" "tools/gyp" "tools/swarming_client";
    do
      pushd "$pkg_dirname/$p" > /dev/null
      git checkout .
      popd > /dev/null
    done
  else
    build_line "Fetching v8 ... this could take awhile"
    fetch v8

    rm -rf "${HAB_CACHE_SRC_PATH:?}/$pkg_dirname"
    mv "$HAB_CACHE_SRC_PATH/v8" "$HAB_CACHE_SRC_PATH/$pkg_dirname"
    ln -s "$HAB_CACHE_SRC_PATH/$pkg_dirname" "$HAB_CACHE_SRC_PATH/v8"
  fi

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
  build_line "Checkout 'tags/$pkg_version'"
  git checkout "tags/$pkg_version"

  build_line "Make sure v8 is in sync ..."
  pushd "$HAB_CACHE_SRC_PATH" > /dev/null
  gclient sync
  popd > /dev/null

  build_line "Patching included binaries in v8"
  binaries=(
    './buildtools/linux64/gn'
    './buildtools/linux64/clang-format'
  )
  _patchelf_binaries "${binaries[@]}"

  build_line "Start with a clean $V8_OUTPUTDIR"
  rm -rf $V8_OUTPUTDIR
}

do_build() {
  export CC
  CC=$(pkg_path_for core/gcc)/bin/gcc
  build_line "Setting CC=$CC"

  export CXX
  CXX=$(pkg_path_for core/gcc)/bin/g++
  build_line "Setting CXX=$CXX"

  export PYTHONPATH
  PYTHONPATH="$(pkg_path_for core/python2)"
  build_line "Setting PYTHONPATH=$PYTHONPATH"

  ./buildtools/linux64/gn gen "$V8_OUTPUTDIR" \
                          --fail-on-unused-args \
                          --args="binutils_path=\"$(pkg_path_for core/binutils)/bin\" \
                                  icu_use_data_file=false \
                                  is_debug=false \
                                  is_clang=false \
                                  is_component_build=true \
                                  ignore_elf32_limitations=true \
                                  linux_use_bundled_binutils=false \
                                  target_cpu=\"x64\" \
                                  use_gold=false \
                                  use_sysroot=false \
                                  v8_enable_backtrace=true \
                                  v8_enable_i18n_support=false \
                                  v8_use_external_startup_data=true"

  $HAB_CACHE_SRC_PATH/depot_tools/ninja -C "$V8_OUTPUTDIR"
}

do_check() {
  build_line "Fixing interpreter for some tools"
  sed -i "s#/usr/bin/env python#$PYTHONPATH/bin/python#" "./tools/run-tests.py"

  # temporarily set this for testing
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$V8_OUTPUTDIR"

  # This will currently fail for 4 tests
  # ref: https://github.com/bdangit/hab-plans/issues/6
  tools/run-tests.py --no-presubmit --outdir "$V8_OUTPUTDIR"
}

do_install() {
  mkdir -p "$pkg_prefix/bin"
  mkdir -p "$pkg_prefix/lib"
  mkdir -p "$pkg_prefix/include/libplatform"

  install -Dm755 "$V8_OUTPUTDIR/d8" "$pkg_prefix/bin"
  install -Dm644 "$V8_OUTPUTDIR/natives_blob.bin" "$pkg_prefix/bin"
  install -Dm644 "$V8_OUTPUTDIR/snapshot_blob.bin" "$pkg_prefix/bin"

  install -Dm755 "$V8_OUTPUTDIR/libv8_libbase.so" "$pkg_prefix/lib"
  install -Dm755 "$V8_OUTPUTDIR/libv8_libplatform.so" "$pkg_prefix/lib"
  install -Dm755 "$V8_OUTPUTDIR/libv8.so" "$pkg_prefix/lib"

  install -Dm644 include/*.h "$pkg_prefix/include"
  install -Dm644 include/libplatform/*.h "$pkg_prefix/include/libplatform"
  install -m644 LICENSE* "$pkg_prefix"
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

_patchelf_binaries() {
  local binaries=("$@")
  for binary in "${binaries[@]}";
  do
    patchelf --interpreter "$(pkg_path_for core/glibc)/lib/ld-linux-x86-64.so.2" \
             --set-rpath "$LD_RUN_PATH" \
             "$binary"
  done
}

_setup_depot_tools() {
  pushd "$HAB_CACHE_SRC_PATH" > /dev/null

  depot_tools_path=$(pwd)/depot_tools
  export PATH="$depot_tools_path":"$PATH"

  if [[ -d "depot_tools" ]]; then
    build_line "Found previous depot_tools, attempting to re-use it."
    return 0
  fi
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  rm -rf "$depot_tools_path"/.git

  build_line "Fix interpreter for 'bin/env' in depot_tools"
  _fix_interpreter_in_path "$depot_tools_path" core/coreutils bin/env

  build_line "Patching included binaries in depot_tools"
  binaries=(
    "$HAB_CACHE_SRC_PATH/depot_tools/ninja-linux64"
  )
  _patchelf_binaries "${binaries[@]}"

  build_line "Enable verbose mode for gclient"
  sed -i 's/gclient\.py" "\$@"/gclient\.py" "\$@" "--verbose"/' \
      "$depot_tools_path/gclient"

  popd > /dev/null
}
