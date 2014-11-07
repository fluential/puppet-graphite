# == Class: graphite::service
#
# Class to start carbon-cache and graphite-web processes
#
class graphite::service {
  $aggregator_ensure = $::graphite::carbon_aggregator ? {
    true    => running,
    default => stopped,
  }

  if empty($::graphite::config::cache_services) { fail('$::graphite::config::cache_services cannot be empty, something went wrong!') }

  service { 'carbon-aggregator':
    ensure     => $aggregator_ensure,
    hasstatus  => true,
    hasrestart => false,
    provider   => upstart,
  }
  if !empty($::graphite::config::relay_services) {
    service { $::graphite::config::relay_services:
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => upstart,
    }
  }
  service { $::graphite::config::cache_services:
    ensure     => running,
    hasstatus  => true,
    hasrestart => false,
    provider   => upstart,
  }

  service { 'graphite-web':
    ensure     => running,
    hasstatus  => true,
    hasrestart => false,
    provider   => upstart,
  }
}
