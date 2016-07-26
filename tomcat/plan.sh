pkg_name=tomcat
pkg_origin=bdangit
pkg_version=8.0.36
pkg_maintainer="Ben Dang <me@bdang.it>"
pkg_license=('MIT')

pkg_source="http://download.nextag.com/apache/tomcat/tomcat-8/v8.0.36/src/apache-tomcat-8.0.36-src.tar.gz"
pkg_shasum=36db67592adda575fc08dd5f0cd3532934d2edb117028e29bdd9f702bf31ab10
pkg_dirname="apache-${pkg_name}-${pkg_version}-src"
pkg_filename="${pkg_dirname}.tar.gz"

pkg_deps=(core/ant core/jdk8)
pkg_expose=(8080)

do_build() {
  cd ${HAB_CACHE_SRC_PATH}/${pkg_dirname}
  # Ant requires JAVA_HOME to be set, and can be set via:
  export JAVA_HOME=$(hab pkg path core/jdk8)
  ant
}

do_install() {
  build_path=$pkg_prefix/build

  mkdir -p $build_path
  cp -r ./output/build/* $build_path
  rm -rf $build_path/webapps/docs
  rm -rf $build_path/webapps/examples

  # make bin executable
  chmod +x $build_path/bin/*.sh

  # swap the existing conf/server.xml for templateized
  rm -f $build_path/conf/server.xml
  ln -s $pkg_svc_config_path/server.xml $build_path/conf/server.xml

  # make logs directory
  mkdir -p $build_path/logs
  chmod +w $build_path/logs

  # make tmp directory\
  mkdir -p $build_path/temp
  chmod +w $build_path/temp
}
