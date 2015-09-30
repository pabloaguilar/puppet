define omegaup::certmanager::cert (
	$ensure = present,
	$country = $::omegaup::certmanager::country,
	$password = 'omegaup',
	$hostname,
) {
	exec { "certmanager-${title}":
		command => "/usr/bin/certmanager cert --root '${omegaup::certmanager::ssl_root}' --country '${country}' --hostname '${hostname}' --output '${title}' --password '${password}'",
		creates => $title,
		requires => [Exec['certmanager-ca'], Package['openjdk-8-jdk']],
	}
}
