pkg_name=cuda
pkg_origin=core
pkg_description="Nvidia CUDA Libraries"
pkg_version=9.2.88
_driverver=396.26
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=('custom')
pkg_source="https://developer.nvidia.com/compute/${pkg_name}/9.2/Prod/local_installers/${pkg_name}_${pkg_version}_${_driverver}_linux"
pkg_filename="${pkg_name}_${pkg_version}_${_driverver}_linux.run"
pkg_shasum=8d02cc2a82f35b456d447df463148ac4cc823891be8820948109ad6186f2667c
pkg_upstream_url="https://developer.nvidia.com/cuda-zone"

pkg_deps=(
  core/coreutils
  core/gcc
  core/gcc-libs
  core/glibc
  core/ncurses
  core/python2
  core/jre8
  core/busybox-static
)
pkg_build_deps=(
  core/linux-headers
  core/patchelf
  core/perl
)

pkg_bin_dirs=(opt/cuda/bin)
pkg_lib_dirs=(
  opt/cuda/lib64
  opt/cuda/nvvm/lib64
)
pkg_include_dirs=(opt/cuda/include)

do_before() {
  if [[ ! -r /usr/bin/perl ]]; then
    ln -sv "$(pkg_path_for perl)/bin/perl" /usr/bin/perl
    _clean_perl=true
  fi

  if [[ ! -r /bin/rm ]]; then
  ln -sv "$(pkg_path_for coreutils)/bin/rm" /bin/rm
  _clean_rm=true
  fi
}

do_download() {
  do_default_download

  # download patch
  download_file "https://developer.nvidia.com/compute/cuda/9.2/Prod/patches/1/cuda_9.2.88.1_linux" cuda_9.2.88.1_linux d2f2d0e91959e4b9a93cd2fa82dced3541e3b8046c3ab7ae335d36f71dbbca13
}

do_unpack() {
  pushd "${HAB_CACHE_SRC_PATH}" > /dev/null
  sh "${pkg_filename}" --extract="${HAB_CACHE_SRC_PATH}/${pkg_dirname}"
  pushd "${pkg_dirname}" > /dev/null
  ./cuda-*.run --noexec --keep
  ./cuda-samples*.run --noexec --keep
  popd > /dev/null
  popd > /dev/null
}

do_prepare() {
  # path hacks
  # 1rd sed line: sets right path to install man files
  # 2rd sed line: hack to lie installer, now detect launch script by root
  # 3rd/4th/5th sed line: sets right path in .desktop files and other .desktop stuff (warnings by desktop-file-validate)
  sed -e "s|/usr/share|${pkg_prefix}/share|g" \
      -e 's|can_add_for_all_users;|1;|g' \
      -e 's|=\\"$prefix\\\"|=/opt/cuda|g' \
      -e 's|Terminal=No|Terminal=false|g' \
      -e 's|ParallelComputing|ParallelComputing;|g' \
      -i pkg/install-linux.pl

  # set right path in Samples Makefiles
  sed 's|\$cudaprefix\\|\\/opt\\/cuda\\|g' -i pkg/install-sdk-linux.pl

  # use python2
  _fix_interpreter_in_path "pkg" '*.py' core/python2 bin/python
  _fix_interpreter_in_path "pkg" '*.py' core/coreutils bin/env

  #TODO: fix sample findgllib_mk
}

do_build() {
  return 0
}

do_install() {
  cd pkg
  export PERL5LIB=.
  perl install-linux.pl -prefix="${pkg_prefix}/opt/cuda" --noprompt
  perl install-sdk-linux.pl -cudaprefix="${pkg_prefix}/opt/cuda" -prefix="${pkg_prefix}/opt/cuda/samples" -noprompt
  sh "${HAB_CACHE_SRC_PATH}/cuda_9.2.88.1_linux" --silent --accept-eula --installdir="${pkg_prefix}/opt/cuda"

  # Hack we need because of glibc 2.26 (https://bugs.archlinux.org/task/55580)
  # without which we couldn't compile anything at all.
  # Super dirty hack. I really hope it doesn't break other stuff!
  # Hopefully we can remove this for later version of cuda.
  sed -i "1 i#define _BITS_FLOATN_H" "${pkg_prefix}/opt/cuda/include/host_defines.h"

  # Needs gcc7
  ln -s "$(pkg_path_for core/gcc)/bin/gcc" "${pkg_prefix}/opt/cuda/bin/gcc"
  ln -s "$(pkg_path_for core/gcc)/bin/g++" "${pkg_prefix}/opt/cuda/bin/g++"

  # # Install profile and ld.so.config files
  mkdir -p "${pkg_prefix}/etc/profile.d"
  cat <<EOF > "${pkg_prefix}/etc/profile.d/cuda.sh"
export PATH=\$PATH:${pkg_prefix}/opt/cuda/bin
EOF
  chmod 0755 "${pkg_prefix}/etc/profile.d/cuda.sh"

  mkdir -p "${pkg_prefix}/etc/ld.so.conf.d"
  cat <<EOF > "${pkg_prefix}/etc/ld.so.conf.d/cuda.conf"
${pkg_prefix}/opt/cuda/lib64
${pkg_prefix}/opt/cuda/lib
${pkg_prefix}/opt/cuda/nvvm/lib64
${pkg_prefix}/opt/cuda/nvvm/lib
EOF
  chmod 0644 "${pkg_prefix}/etc/ld.so.conf.d/cuda.conf"

  mkdir -p "${pkg_prefix}/share/licenses"
  ln -s "${pkg_prefix}/opt/cuda/doc/pdf/EULA.pdf" "${pkg_prefix}/share/licenses/EULA.pdf"

  # Remove redundant man and samples
  rm -fr "${pkg_prefix}/opt/cuda/doc/man"
  rm -fr "${pkg_prefix}/opt/cuda/cuda-samples"
  rm -fr "${pkg_prefix}/usr/share/man/man3/deprecated.3"*

  # Remove included copy of java and link to system java
  rm -fr  "${pkg_prefix}/opt/cuda/jre"
  sed 's|../jre/bin/java|$(pkg_path_for core/jre8)/bin/java|g' \
    -i "${pkg_prefix}/opt/cuda/libnsight/nsight.ini" \
    -i "${pkg_prefix}/opt/cuda/libnvvp/nvvp.ini"

  # Remove unused files
  rm -fr "${pkg_prefix}/opt/cuda/"{bin,samples}"/.uninstall_manifest_do_not_delete.txt"
  rm -fr "${pkg_prefix}/opt/cuda/samples/uninstall_cuda_samples"*.pl
  rm -fr "${pkg_prefix}/opt/cuda/bin/cuda-install-samples"*.sh
  rm -fr "${pkg_prefix}/opt/cuda/bin/uninstall_cuda_toolkit"*.pl

  # patch some bins
  build_line "patch ${pkg_prefix}/opt/cuda/nvvm/bin/cicc"
  patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" \
    --set-rpath "${LD_RUN_PATH}" \
    "${pkg_prefix}/opt/cuda/nvvm/bin/cicc"

  build_line "patch ${pkg_prefix}/opt/cuda/libnvvp/nvvp"
  patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" \
    --set-rpath "${LD_RUN_PATH}" \
    "${pkg_prefix}/opt/cuda/libnvvp/nvvp"

  build_line "patch ${pkg_prefix}/opt/cuda/libnsight/nsight"
  patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" \
    --set-rpath "${LD_RUN_PATH}" \
    "${pkg_prefix}/opt/cuda/libnsight/nsight"

  for bin in bandwidthTest busGrind deviceQuery nbody oceanFFT randomFog vectorAdd; do
    build_line "patch ${pkg_prefix}/opt/cuda/bin/${bin}"
    patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" \
      --set-rpath "${LD_RUN_PATH}" \
      "${pkg_prefix}/opt/cuda/extras/demo_suite/${bin}"
  done

  for bin in bin2c cudafe++ cuobjdump fatbinary nvcc nvdisasm nvlink nvprof nvprune ptxas; do
    build_line "patch ${pkg_prefix}/opt/cuda/bin/${bin}"
    patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" \
      --set-rpath "${LD_RUN_PATH}" \
      "${pkg_prefix}/opt/cuda/bin/${bin}"
  done

  for bin in cuda-gdbserver cuda-memcheck gpu-library-advisor; do
    build_line "patch ${pkg_prefix}/opt/cuda/bin/${bin}"
    patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" \
      --set-rpath "${LD_RUN_PATH}" \
      "${pkg_prefix}/opt/cuda/bin/${bin}"
  done

  # cuda-gdb
  # note: libncurses 6.1 is "designed to be source-compatible with 5.0 through 6.0"
  build_line "patch ${pkg_prefix}/opt/cuda/bin/cuda-gdb"
  patchelf --interpreter "$(pkg_path_for glibc)/lib/ld-linux-x86-64.so.2" "${pkg_prefix}/opt/cuda/bin/cuda-gdb"
  patchelf --replace-needed libncurses.so.5 libncurses.so.6 "${pkg_prefix}/opt/cuda/bin/cuda-gdb"
  patchelf --set-rpath "${LD_RUN_PATH}" "${pkg_prefix}/opt/cuda/bin/cuda-gdb"

  fix_interpreter "${pkg_prefix}/opt/cuda/bin/computeprof" core/busybox-static bin/sh
  fix_interpreter "${pkg_prefix}/opt/cuda/bin/nvvp" core/busybox-static bin/sh
  fix_interpreter "${pkg_prefix}/opt/cuda/bin/nsight" core/busybox-static bin/sh
  fix_interpreter "${pkg_prefix}/opt/cuda/bin/nsight_ee_plugins_manage.sh" core/busybox-static bin/sh

  # patch some libs
  for lib in OpenCL accinj64 cublas cudart cufft cufftw cuinj64 curand cusolver cusparse nppc nppial nppicc nppicom nppidei nppif nppig nppim nppist nppisu nppim nppist nppisu nppitc npps nvToolsExt nvblas nvgraph nvrtc-builtins nvrtc; do
    build_line "patch ${pkg_prefix}/opt/cuda/lib64/lib${lib}.so"
    patchelf --set-rpath "${LD_RUN_PATH}" "${pkg_prefix}/opt/cuda/lib64/lib${lib}.so"
  done

  for lib in $(ls "${pkg_prefix}/opt/cuda/lib64/stubs/"*.so); do
    build_line "patch ${lib}"
    patchelf --set-rpath "${LD_RUN_PATH}" "${lib}"
  done
}

do_strip() {
  return 0
}

do_end() {
  if [[ -n "$_clean_perl" ]]; then
    rm -fv /usr/bin/perl
  fi

  if [[ -n "$_clean_rm" ]]; then
  rm -fv /bin/rm
  fi
}

# private #
_fix_interpreter_in_path() {
  local path=$1
  local fileending=$2
  local pkg=$3
  local int=$4

  # shellcheck disable=SC2016
  # I need these to be evaluated at exec time
  find "$path" -name "$fileending" -type f \
    -exec grep -Iq . {} \; \
    -exec sh -c 'head -n 1 "$1" | grep -q "$2"' _ {} "$int" \; \
    -exec sh -c 'echo "$1"' _ {} \; > /tmp/fix_interpreter_in_path_list

  grep -v '^ *#' < /tmp/fix_interpreter_in_path_list | while IFS= read -r line
  do
    fix_interpreter "$line" "$pkg" "$int"
  done
  rm -rf /tmp/fix_interpreter_in_path_list
}
