pkg_origin=bdangit
pkg_name=glib
pkg_version='2.50.1'
pkg_description="$(cat << EOF
  GLib is a general-purpose utility library, which provides many useful data
  types, macros, type conversions, string utilities, file utilities, a
  mainloop abstraction, and so on. It works on many UNIX-like platforms, as
  well as Windows and OS X.
EOF
)"
pkg_source="http://download.gnome.org/sources/glib/$(echo $pkg_version | cut -d. -f1-2)/$pkg_name-$pkg_version.tar.xz"
pkg_license=('LGPL-2.0')
pkg_maintainer='Ben Dang <me@bdang.it>'
pkg_upstream_url="https://developer.gnome.org/glib/stable/glib.html"
pkg_shasum="2ef87a78f37c1eb5b95f4cc95efd5b66f69afad9c9c0899918d04659cf6df7dd"
pkg_deps=(
  core/glibc
)
pkg_build_deps=(
  core/make
  core/pkg-config
  core/gcc
  core/gettext
  core/libffi
  core/libiconv
  core/zlib
  core/python2
  core/util-linux
)
pkg_bin_dirs=(bin)
pkg_lib_dirs=(lib)
pkg_include_dirs=(include)

do_build() {
  ./configure --prefix="$pkg_prefix"
  make
}
