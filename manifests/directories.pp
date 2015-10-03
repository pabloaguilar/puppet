class omegaup::directories {
	file { ['/var/lib/omegaup', '/var/log/omegaup']: ensure => 'directory' }
}
