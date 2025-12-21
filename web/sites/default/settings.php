<?php

/**
 * @file
 * Drupal site-specific configuration file.
 */

// Database settings, overridden per environment.
$databases = [];
$databases['default']['default']['prefix'] = '';
$databases['default']['default']['port'] = '3306';
$databases['default']['default']['namespace'] = 'Drupal\\Core\\Database\\Driver\\mysql';
$databases['default']['default']['driver'] = 'mysql';

// Lando settings.
if (getenv('LANDO') === 'ON') {
  $databases['default']['default']['database'] = $_ENV['DB_NAME'] ?? '';
  $databases['default']['default']['username'] = $_ENV['DB_USER'] ?? '';
  $databases['default']['default']['password'] = $_ENV['DB_PASS'] ?? '';
  $databases['default']['default']['host'] = $_ENV['DB_HOST'] ?? '';
}

// Salt for one-time login links, cancel links, form tokens, etc.
$settings['hash_salt'] = $_ENV['HASH_SALT'] ?? '';

// Location of the site configuration files.
$settings['config_sync_directory'] = '../config/sync';

// Load services definition file.
$settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.yml';

/**
 * The default list of directories that will be ignored by Drupal's file API.
 *
 * By default ignore node_modules and bower_components folders to avoid issues
 * with common frontend tools and recursive scanning of directories looking for
 * extensions.
 *
 * @see file_scan_directory()
 * @see \Drupal\Core\Extension\ExtensionDiscovery::scanDirectory()
 */
$settings['file_scan_ignore_directories'] = [
  'node_modules',
  'bower_components',
];

// Environment-specific settings.
$env = $_ENV['ENVIRONMENT_NAME'];
switch ($env) {
  case 'production':
    $settings['simple_environment_indicator'] = 'DarkRed Production';
    // Warden settings.
    $config['warden.settings']['warden_token'] = $_ENV['WARDEN_TOKEN'];
    break;

  case 'main':
    $settings['simple_environment_indicator'] = 'DarkBlue Stage';
    break;

  case 'local':
  case 'lando':
  case 'ddev':
    $settings['simple_environment_indicator'] = 'DarkGreen Local';
    // Skip file system permissions hardening.
    $settings['skip_permissions_hardening'] = TRUE;
    // Skip trusted host pattern.
    $settings['trusted_host_patterns'] = ['.*'];
    // Enable CSS and JS preprocess.
    $config['system.performance']['css']['preprocess'] = TRUE;
    $config['system.performance']['js']['preprocess'] = TRUE;
    break;

  default:
    $settings['simple_environment_indicator'] = '#2F2942 Test';
    break;
}

/**
 * Load local development override configuration, if available.
 *
 * Use settings.local.php to override variables on secondary (staging,
 * development, etc) installations of this site. Typically used to disable
 * caching, JavaScript/CSS compression, re-routing of outgoing emails, and
 * other things that should not happen on development and testing sites.
 */
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}

// Silta cluster configuration overrides.
if (isset($_ENV['SILTA_CLUSTER']) && file_exists($app_root . '/' . $site_path . '/settings.silta.php')) {
  include $app_root . '/' . $site_path . '/settings.silta.php';
}

// Automatically generated include for settings managed by ddev.
$ddev_settings = dirname(__FILE__) . '/settings.ddev.php';
if (getenv('IS_DDEV_PROJECT') == 'true' && is_readable($ddev_settings)) {
  require $ddev_settings;
}

/**
 * State caching.
 *
 * State caching uses the cache collector pattern to cache all requested keys
 * from the state API in a single cache entry, which can greatly reduce the
 * amount of database queries. However, some sites may use state with a
 * lot of dynamic keys which could result in a very large cache.
 */
$settings['state_cache'] = TRUE;
