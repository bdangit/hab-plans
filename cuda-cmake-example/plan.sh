pkg_origin=bdangit
pkg_name=cuda-cmake-example
pkg_version='0.1.0'
pkg_description="cuda cmake example"
pkg_license=('MIT')
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_deps=(
  bdangit/gcc7-libs
  core/glibc
  bdangit/cuda-libs
  core/zeromq
)
pkg_build_deps=(
  bdangit/cuda
  core/make
  core/cmake
)
pkg_bin_dirs=(bin)

BUILDDIR='build'

do_prepare() {
  mkdir -pv "${BUILDDIR}"
}

do_build() {
  pushd "${BUILDDIR}" > /dev/null

  CUDA_PATH=$(pkg_path_for bdangit/cuda)
  GLIBC_PATH=$(pkg_path_for glibc)

  cmake -DCMAKE_INSTALL_PREFIX="${pkg_prefix}" \
    -DCUDA_TOOLKIT_ROOT_DIR="${CUDA_PATH}" \
    -DCUDA_rt_LIBRARY="${GLIBC_PATH}/lib/librt.so" \
    ..
  make

  popd > /dev/null
}

do_install() {
  pushd "${BUILDDIR}" > /dev/null

  make install

  popd > /dev/null
}
