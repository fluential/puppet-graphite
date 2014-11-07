# == Class: graphite::config
#
# Class to set up all graphite related configuration files and dependencies
#
class graphite::config {

  $admin_password                 = $::graphite::admin_password
  $bind_address                   = $::graphite::bind_address
  $port                           = $::graphite::port
  $root_dir                       = $::graphite::root_dir
  $user                           = $::graphite::user
  $group                          = $::graphite::group
  $carbon_max_cache_size          = $::graphite::carbon_max_cache_size
  $carbon_max_updates_per_second  = $::graphite::carbon_max_updates_per_second
  $carbon_max_creates_per_minute  = $::graphite::carbon_max_creates_per_minute
  $cache_default_override_conf    = $::graphite::cache_default_override_conf
  $cache_line_receiver_port       = $::graphite::cache_line_receiver_port
  $cache_pickle_receiver_port     = $::graphite::cache_pickle_receiver_port
  $cache_query_port               = $::graphite::cache_query_port
  $cache_instances_keys           = keys($::graphite::cache_instances)
  $relay_instances_keys           = keys($::graphite::relay_instances)
  $relay_line_receiver_port       = $::graphite::relay_line_receiver_port
  $relay_pickle_receiver_port     = $::graphite::relay_pickle_receiver_port
  $relay_default_override_conf    = $::graphite::relay_default_override_conf

  $cache_default_conf = {
    'LOCAL_DATA_DIR'            => "${root_dir}/storage/whisper",
    'USER'                      => $user,
    'MAX_CACHE_SIZE'            => $carbon_max_cache_size,
    'MAX_UPDATES_PER_SECOND'    => $carbon_max_updates_per_second,
    'MAX_CREATES_PER_MINUTE'    => $carbon_max_creates_per_minute,
    'LINE_RECEIVER_INTERFACE'   => '0.0.0.0',
    'LINE_RECEIVER_PORT'        => $cache_line_receiver_port,
    'PICKLE_RECEIVER_INTERFACE' => '0.0.0.0',
    'CACHE_QUERY_INTERFACE'     => '0.0.0.0',
    'CACHE_QUERY_PORT'          => $cache_query_port,
    'ENABLE_UDP_LISTENER'       => 'False',
    'UDP_RECEIVER_INTERFACE'    => '0.0.0.0',
    'UDP_RECEIVER_PORT'         => 2003,
    'PICKLE_RECEIVER_INTERFACE' => '0.0.0.0',
    'PICKLE_RECEIVER_PORT'      => $cache_pickle_receiver_port,
    'LOG_LISTENER_CONNECTIONS'  => 'False',
    'USE_INSECURE_UNPICKLER'    => 'False',
    'USE_FLOW_CONTROL'          => 'True',
    'LOG_UPDATES'               => 'False',
    'LOG_CACHE_HITS'            => 'False',
    'LOG_CACHE_QUEUE_SORTS'     => 'False',
    'CACHE_WRITE_STRATEGY'      => 'sorted',
    'WHISPER_AUTOFLUSH'         => 'False',
    'WHISPER_FALLOCATE_CREATE'  => 'True',
  }

  $relay_default_conf = {
    'LINE_RECEIVER_INTERFACE'    => '0.0.0.0',
    'LINE_RECEIVER_PORT'         => $relay_line_receiver_port,
    'PICKLE_RECEIVER_PORT'       => $relay_pickle_receiver_port,
    'LOG_LISTENER_CONNECTIONS'   => 'False',
    'RELAY_METHOD'               => 'consistent-hashing',
    'REPLICATION_FACTOR'         => 1,
    'DESTINATIONS'               => '127.0.0.1:2004:a',
    'MAX_DATAPOINTS_PER_MESSAGE' => 500,
    'MAX_QUEUE_SIZE'             => 10000,
    'USE_FLOW_CONTROL'           => 'True'
  }

  if ($::graphite::aggregation_rules_source == undef and
      $::graphite::aggregation_rules_content == undef) {
    $aggregation_rules_ensure = absent
  } else {
    $aggregation_rules_ensure = present
  }

  if ($::graphite::storage_aggregation_source == undef and
      $::graphite::storage_aggregation_content == undef) {
    $storage_aggregation_source = 'puppet:///modules/graphite/storage-aggregation.conf'
    $storage_aggregation_content = undef
  } else {
    $storage_aggregation_source = $::graphite::storage_aggregation_source
    $storage_aggregation_content = $::graphite::storage_aggregation_content
  }

  if ($::graphite::storage_schemas_source == undef and
      $::graphite::storage_schemas_content == undef) {
    $storage_schemas_source = 'puppet:///modules/graphite/storage-schemas.conf'
    $storage_schemas_content = undef
  } else {
    $storage_schemas_source = $::graphite::storage_schemas_source
    $storage_schemas_content = $::graphite::storage_schemas_content
  }

  if ($::graphite::carbon_source == undef and
      $::graphite::carbon_content == undef) {
    $carbon_content = template('graphite/carbon.conf')
    $carbon_source = undef
  } else {
    $carbon_source = $::graphite::carbon_source
    $carbon_content = $::graphite::carbon_content
  }

  $initdb_cmd = $::graphite::use_python_pip ? {
    true  => "${root_dir}/bin/python ${root_dir}/lib/graphite/manage.py \
    syncdb --noinput",
    false => 'python manage.py syncdb --noinput'
  }

  file { '/etc/init/carbon-aggregator.conf':
    ensure  => present,
    content => template('graphite/upstart/carbon-aggregator.conf'),
    mode    => '0555',
  }

  file { '/etc/init/carbon-cache.conf':
    ensure  => present,
    content => template('graphite/upstart/carbon-cache.conf'),
    mode    => '0555',
  }

  graphite::gencacheinstances { $cache_instances_keys:
    notify => Exec['set_graphite_ownership']
  }
  graphite::genrelayinstances { $relay_instances_keys:
    notify => Exec['set_graphite_ownership']
  }

  if !empty($cache_instances_keys) {
    $cache_services = prefix($cache_instances_keys, 'carbon-cache-')
  } else {
    $cache_services = undef
  }

  if !empty($relay_instances_keys) {
    $relay_services = prefix($relay_instances_keys, 'carbon-relay-')
  } else {
    $relay_services = undef
  }

  file { '/etc/init/graphite-web.conf':
    ensure  => present,
    content => template('graphite/upstart/graphite-web.conf'),
    mode    => '0555',
  }

  file { "${root_dir}/conf/carbon.conf":
    ensure  => present,
    content => $carbon_content,
    source  => $carbon_source,
    owner   => $::graphite::user,
    group   => $::graphite::group,
    mode    => '0444',
  }

  file { "${root_dir}/conf/aggregation-rules.conf":
    ensure  => $aggregation_rules_ensure,
    content => $::graphite::aggregation_rules_content,
    source  => $::graphite::aggregation_rules_source,
    owner   => $::graphite::user,
    group   => $::graphite::group,
    mode    => '0444',
  }

  file { "${root_dir}/conf/storage-aggregation.conf":
    ensure  => present,
    content => $storage_aggregation_content,
    source  => $storage_aggregation_source,
    owner   => $::graphite::user,
    group   => $::graphite::group,
    mode    => '0444',
  }

  file { "${root_dir}/conf/storage-schemas.conf":
    ensure  => present,
    content => $storage_schemas_content,
    source  => $storage_schemas_source,
    owner   => $::graphite::user,
    group   => $::graphite::group,
    mode    => '0444',
  }

  file { [ "${root_dir}/storage", "${root_dir}/storage/whisper" ]:
    ensure => directory,
  }

  # Using Exec instead of File resource, simply because the graphite directory
  # can grow very large, and managing large directories with Puppet can lead
  # to memory starvation.
  # The exec will use xargs and parralise chmod, so even for large directories
  # it should run pretty quickly.
  exec { 'set_graphite_ownership':
    command     => "/usr/bin/env find ${root_dir}/storage ${root_dir}/webapp -print0 | \
                      xargs -0 -n 50 -P 4 \
                      chown ${::graphite::user}:${graphite::group}",
    refreshonly => true,
    require     => File["${root_dir}/storage"],
    subscribe   => [
                      File['/etc/init/graphite-web.conf'],
                      File["${root_dir}/storage"],
                  ],
    before      => [ Service['graphite-web'], Service[$cache_services] ],
  }

  exec { 'init-db':
    command   => $initdb_cmd,
    cwd       => "${root_dir}/webapp/graphite",
    creates   => "${root_dir}/storage/graphite.db",
    subscribe => File["${root_dir}/storage"],
    require   => File["${root_dir}/webapp/graphite/initial_data.json"],
  }

  file { "${root_dir}/webapp/graphite/initial_data.json":
    ensure  => present,
    require => File["${root_dir}/storage"],
    content => template('graphite/initial_data.json'),
  }

  file { "${root_dir}/storage/graphite.db":
    owner     => $::graphite::user,
    mode      => '0664',
    subscribe => Exec['init-db'],
  }

  file { "${root_dir}/storage/log/webapp/":
    ensure => 'directory',
    owner  => $::graphite::user,
    mode   => '0775',
  }

  file { "${root_dir}/webapp/graphite/local_settings.py":
    ensure  => present,
    source  => 'puppet:///modules/graphite/local_settings.py',
    owner   => $::graphite::user,
    group   => $::graphite::group,
    mode    => '0444',
    require => File["${root_dir}/storage"],
  }

}
