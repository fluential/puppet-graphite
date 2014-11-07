# == Class: graphite
#
# Class to install and configure the Graphite metric aggregation and
# graphing system.
#
# The main difference to usual graphite installations is that we always use instances explicitly here, even if there is only one running
# That means that you should alway do something like:
#   * start carbon-cache-a
#   * start carbon-relay-a
#
# This approach simplifies code base
#
# === Parameters
#
# [*admin_password*]
#   The (hashed) initial admin password.
#
# [*bind_address*]
#   The address on which to serve the graphite-web user interface.
#   Default: 127.0.0.1
#
# [*port*]
#   The port on which to serve the graphite-web user interface.
#   Default: 8000
#
# [*root_dir*]
#   Where to install Graphite.
#   Default: /opt/graphite
#
# [*carbon_aggregator*]
#   Optional: Boolean, whether to run carbon-aggregator. You will need to
#   provide an appropriate `carbon_content` or `carbon_source` config.
#
# [*carbon_max_cache_size*]
#   Optional: Set Carbon MAX_CACHE_SIZE
#
# [*carbon_max_creates_per_minute*]
#   Optional: Set Carbon MAX_CREATES
#
# [*carbon_max_updates_per_second*]
#   Optional: Set Carbon MAX_UPDATES_PER_MIN
#
# [*aggregation_rules_content*]
#   Optional: the content of the aggregation-rules.conf file.
#
# [*aggregation_rules_source*]
#   Optional: the source of the aggregation-rules.conf file.
#
# [*storage_aggregation_content*]
#   Optional: the content of the storage-aggregation.conf file.
#
# [*storage_aggregation_source*]
#   Optional: the source of the storage-aggregation.conf file.
#
# [*storage_schemas_content*]
#   Optional: the content of the storage-schemas.conf file.
#
# [*storage_schemas_source*]
#   Optional: the source of the storage-schemas.conf file.
#
# [*carbon_content*]
#   Optional: the content of the carbon.conf file.
#
# [*cache_instances*]
#   List of cache instances to be running with its hash config parameters.
#   Configuration is going to be discovered automatically, you can just specify instances { 'a' => {}, 'b' => {}, 'c' => {} } and job done
#
# [*cache_default_override_conf*]
#   Override default config settings for all instances. Instance specific config can be passed via *cache_instances*
#
# [*cache_line_receiver_port*]
#   Carbon cache LINE_RECEIVER_PORT - this is also used as a starting port to increment from for additional instances
#
# [*cache_pickle_receiver_port*]
#   Carbon cache PICKLE_RECEIVER_PORT - this is also used as a starting port to increment from for additional instances
#
# [*cache_query_port*]
#   Carbon cache CACHE_QUERY_PORT - this is also used as a starting port to increment from for additional instances
#
# [*relay_instances*]
#   List of relay instances to be running with its hash config parameters
#   Configuration is going to be discovered automatically, you can just specify instances { 'a' => {}, 'b' => {}, 'c' => {} } and job done
#
# [*relay_default_override_conf*]
#   Override default config settings for all instances. Instance specific config can be passed via *relay_instances*
#
# [*carbon_source*]
#   Optional: the source of the carbon.conf file.
#
# [*version*]
#   Graphite package version to install.
#
# [*user*]
#   Optional: User account used for Graphite services
#
# [*group*]
#   Optional: Group account used for Graphite services
#
# [*manage_user*]
#   Optional: Manage the user and group account with Puppet
#
# [*use_python_pip*]
#   Optional: Use Python pip to install Graphite services. If set to
#   false, then 'Package' resource type is used.
#
# [*whisper_pkg_name*]
#   Optional: Whisper package name
#
# [*carbon_pkg_name*]
#   Optional: Carbon package name
#
# [*graphite_web_pkg_name*]
#   Optional: Grpahite-Web package name
#
class graphite(
  $admin_password = $graphite::params::admin_password,
  $bind_address = $graphite::params::bind_address,
  $port = $graphite::params::port,
  $root_dir = $graphite::params::root_dir,
  $carbon_aggregator = false,
  $carbon_max_cache_size = 'inf',
  $carbon_max_creates_per_minute = 'inf',
  $carbon_max_updates_per_second = 'inf',
  $aggregation_rules_content = undef,
  $aggregation_rules_source = undef,
  $storage_aggregation_content = undef,
  $storage_aggregation_source = undef,
  $storage_schemas_content = undef,
  $storage_schemas_source = undef,
  $carbon_source = undef,
  $carbon_content = undef,
  $cache_line_receiver_port = 2003,
  $cache_pickle_receiver_port = 2004,
  $cache_query_port = 7002,
  $relay_line_receiver_port = 2013,
  $relay_pickle_receiver_port = 2014,
  $cache_instances = {'a' => {} },
  $relay_instances = {},
  $cache_default_override_conf = {},
  $relay_default_override_conf = {},
  $version = $graphite::params::version,
  $user = $graphite::params::user,
  $group = $graphite::params::group,
  $manage_user = true,
  $use_python_pip = true,
  $whisper_pkg_name = 'whisper',
  $carbon_pkg_name = 'carbon',
  $graphite_web_pkg_name = 'graphite-web',
) inherits graphite::params {
  validate_string(
    $admin_password,
    $version,
    $user,
    $group,
  )

  if empty($cache_instances) { fail('You need to provide at least one cache instance, configuration hash can be empty, defaults will be used') }
  validate_bool($manage_user)
  validate_hash($cache_default_override_conf)
  validate_hash($cache_instances)
  validate_hash($relay_instances)

  #  if ( (!empty($cache_instances) and empty($cache_destinations))  or (empty($cache_instances) and !empty($cache_destinations)) ) {
  #   fail('You need to provide both $cache_instances and $cache_destinations to configure cluster') 
  #}

  if $::graphite::manage_user {
    class{'graphite::user':}
    Class['graphite::user'] -> Class['graphite::config']
  }

  if $use_python_pip {
    class{'graphite::deps':}
    Class['graphite::deps'] -> Class['graphite::install']
  }

  class{'graphite::install': } ->
  class{'graphite::config': } ~>
  class{'graphite::service': } ->
  Class['graphite']
}
