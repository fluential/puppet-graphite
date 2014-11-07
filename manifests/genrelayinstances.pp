# Generate carbon relay upstart scripts
define graphite::genrelayinstances ($instance = $title, $ensure = 'present' ) {
  file { "/etc/init/carbon-relay-${instance}.conf":
    ensure  => present,
    content => template('graphite/upstart/carbon-relay.conf'),
    mode    => '0555',
  }
}
