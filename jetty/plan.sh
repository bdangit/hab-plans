pkg_name=jenkins
pkg_description="The Jetty Web Server provides an HTTP server and Servlet container capable of serving static and dynamic content either from a standalone or embedded instantiations."
pkg_origin=bdangit
pkg_version="9.3.11.v20160721"
pkg_maintainer="Ben Dang <me@bdang.it>"
pkg_license=('Apache-2.0 and Eclipse Public License 1.0')
pkg_upstream_url="https://www.eclipse.org/jetty/"
pkg_source="http://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${pkg_version}/jetty-distribution-${pkg_version}.tar.gz"
pkg_shasum=6f720a39324ba02491c5dd598039f9cda1746d45c26594f8189692058f9f4264
pkg_dirname="${pkg_name}-distribution-${pkg_version}"
pkg_expose=(8080 8443)

pkg_deps=(
  core/jdk8
  core/coreutils
)

do_build() {
  return 0
}

do_install() {
  build_line "Performing install"
  mkdir -p "${pkg_prefix}/jetty"
  cp -vR ./* "${pkg_prefix}/jetty"
}
