class omegaup::java {
  if $::lsbdistcodename == 'trusty' {
    $jre_package = 'openjdk-7-jre'
    $jre_directory = '/usr/lib/jvm/java-7-openjdk-amd64/jre'
  } else {
    $jre_package = 'openjdk-8-jre'
    $jre_directory = '/usr/lib/jvm/java-8-openjdk-amd64/jre'
  }

  package { $jre_package: ensure => installed }
}
