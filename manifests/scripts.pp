class omegaup::scripts {
	file { '/tmp/mkhexdirs.sh':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/mkhexdirs.sh',
		mode   => '0700',
	}
}
