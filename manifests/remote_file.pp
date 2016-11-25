# Downloads a file from an URL.
define omegaup::remote_file(
  $source=undef,
  $mode='0644',
  $owner=undef,
  $group=undef,
) {
  exec { "wget_${title}":
    command => "/usr/bin/wget -q ${source} -O ${title}",
    creates => $title,
  }

  file { $title:
    ensure  => 'file',
    mode    => $mode,
    owner   => $owner,
    group   => $group,
    require => Exec["wget_${title}"],
  }
}
