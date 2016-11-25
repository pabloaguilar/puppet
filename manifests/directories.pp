# Creates directories needed at runtime.
class omegaup::directories {
  file { ['/var/lib/omegaup', '/var/log/omegaup']: ensure => 'directory' }
}

# vim:expandtab ts=2 sw=2
