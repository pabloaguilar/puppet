define omegaup::certmanager::cert (
	$ensure = present,
	$country = $::omegaup::certmanager::country,
	$password = 'omegaup',
	$owner = undef,
	$group = undef,
	$mode = undef,
	$hostname,
) {
	include omegaup::java

	exec { "certmanager-${title}":
		command => "/usr/bin/certmanager cert --root '${omegaup::certmanager::ssl_root}' --country '${country}' --hostname '${hostname}' --output '${title}' --password '${password}'",
		creates => $title,
		require => [Exec['certmanager-ca'], Package[$::omegaup::java::jre_package]],
	}

	file { $title:
		owner => $owner,
		group => $group,
		mode => $mode,
		require => [Exec["certmanager-${title}"]],
	}
}
