class omegaup::users {
	user { ['omegaup', 'www-data']: ensure => present }
}
