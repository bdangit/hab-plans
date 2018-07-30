# cuda

[GPU-accelerated Libraries](https://developer.nvidia.com/cuda-zone) for Computing on NVIDIA devices.

## Maintainers

* The Habitat Maintainers: <humans@habitat.sh>
* Ben Dang: <me@bdang.it>

## Type of Package

Binary package

## Usage

To compile cuda code (ie. `*.cu`), just add `core/cuda` to your `plan.sh`.  You will then have
access to compiler tools like `nvcc`, `cuda-gdb` and more.  Furthermore, `LD_RUN_PATH`, `CFLAGS`,
`CXXFLAGS`, `CPPFLAGS`, and `LDFLAGS` will be updated with any of the cuda shared/static libraries.

If you require shared libraries during runtime, it is recommended that you add `core/cuda-libs` to
`pkg_deps` and add `core/cuda` to `pkg_build_deps`.

### Example `plan.sh`

```shell
pkg_name=myawesomecudaapp
pkg_origin=myorigin

pkg_deps=(
  core/cuda-libs
  core/gcc-libs
)
pkg_build_deps=(
  core/cuda
  core/make
)

do_build() {
  nvcc -o myawesomecudaapp source.cu
}
```
