# Generate carbon cache upstart scripts
define graphite::gencacheinstances ($instance = $title, $ensure = 'present' ) {
  file { "/etc/init/carbon-cache-${instance}.conf":
    ensure  => present,
    content => template('graphite/upstart/carbon-cache.conf'),
    mode    => '0555',
  }
}
