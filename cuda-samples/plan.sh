pkg_origin=bdangit
pkg_name=cuda-samples
pkg_version='9.2'
pkg_description="$(cat << EOF
  Samples for CUDA Developers which demonstrates features in CUDA Toolkit
EOF
)"
pkg_source="https://github.com/NVIDIA/${pkg_name}/archive/v${pkg_version}.tar.gz"
pkg_license=('custom')
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_upstream_url="https://github.com/NVIDIA/cuda-samples"
pkg_shasum="4b172847196d5b2ab645625dd7953ddf5cffa04b2a3c45689d33ef92fc953d90"
pkg_deps=(
  bdangit/cuda-libs
  core/gcc-libs
  core/glibc
)
pkg_build_deps=(
  core/cuda
  core/make
)

pkg_bin_dirs=(bin)

do_build() {
  export CUDA_PATH=$(pkg_path_for core/cuda)
  make
}

do_install() {
  cp -av bin/x86_64/linux/release/* "${pkg_prefix}/bin/"
}
