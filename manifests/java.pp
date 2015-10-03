class omegaup::java {
	package { ['openjdk-8-java', 'ca-certificates']: ensure => installed }
}
