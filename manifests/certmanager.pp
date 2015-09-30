class omegaup::certmanager (
	$ssl_root = '/etc/certmanager',
	$ca_name = 'omegaUp Certificate Authority',
	$country = 'MX',
) {
	file { '/usr/bin/certmanager':
		ensure => 'file',
		source => 'puppet:///modules/omegaup/certmanager',
		owner  => 'root',
		group  => 'root',
		mode   => '0755',
	}
	file { $ssl_root:
		ensure => 'directory',
		owner  => 'root',
		group  => 'root',
	}
	exec { "certmanager-ca":
		command => "/usr/bin/certmanager init --root '${::omegaup::certmanager::ssl_root}' --ca-name '${ca_name}' --country '${country}'",
		creates => "${::omegaup::certmanager::ssl_root}/ca.crt",
		requires => [File['/usr/bin/certmanager'], Package['openjdk-8-jdk'],
		             File[$::omegaup::certmanager::ssl_root]],
	}
}
