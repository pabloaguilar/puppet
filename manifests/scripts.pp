class omegaup::scripts {
	file { '/usr/bin/mkhexdirs':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/mkhexdirs.sh',
		mode   => '0755',
		owner  => 'root',
		group  => 'root',
	}
}
