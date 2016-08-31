pkg_name=jenkins
pkg_description="Jenkins is an automation engine with an unparalleled plugin ecosystem to support all of your favorite tools in your delivery pipelines, whether your goal is continuous integration, automated testing, or continuous delivery."
pkg_origin=bdangit
pkg_version="2.7.2"
pkg_maintainer="Ben Dang <me@bdang.it>"
pkg_license=('MIT')
pkg_upstream_url="https://jenkins.io/"
pkg_source="https://github.com/jenkinsci/jenkins/archive/jenkins-${pkg_version}.tar.gz"
pkg_shasum=0907967bffb900c5363ec3655946bbd1bf62df943d581a6393026bc0ae01755f
pkg_expose=(8080)

pkg_deps=(
  core/jdk8/8u102
  core/coreutils
)

pkg_build_deps=(
  core/maven
  core/cacerts
  core/node
)

do_build() {
  export JAVA_HOME
  JAVA_HOME=$(pkg_path_for core/jdk8)
  build_line "JAVA_HOME=$JAVA_HOME"

  cd "$HAB_CACHE_SRC_PATH/jenkins-${pkg_dirname}"
  mvn clean install -pl war -am -DskipTests
}

do_install() {
  build_line "Performing install"
  mkdir -p "${pkg_prefix}"
  install "$HAB_CACHE_SRC_PATH/jenkins-${pkg_dirname}/war/target/$pkg_name".war "$pkg_prefix"/"$pkg_name".war
}
