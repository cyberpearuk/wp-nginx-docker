<?php

function getEnvVar($varname, $default = false) {
    $env = getenv($varname);
    if ($env === false) {
        return $default;
    } else if ($env === 'true') {
        return true;
    } else if ($env === 'false') {
        return false;
    } else {
        // Clear variable
        putenv($varname);
        return $env;
    }
}

// Fix for HTTP 301 Redirect loop when using SSL behind reverse proxy.
if ($_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
   $_SERVER['HTTPS']='on';
}

// Allow setting default theme
$defaultTheme = getEnvVar('WP_DEFAULT_THEME');
if (!empty($defaultTheme)) {
    define('WP_DEFAULT_THEME', $defaultTheme);
}
define('DB_NAME', getEnvVar('WORDPRESS_DB_NAME', 'wordpress'));
define('DB_USER', getEnvVar('WORDPRESS_DB_USER'));
define('DB_PASSWORD', getEnvVar('WORDPRESS_DB_PASSWORD'));
define('DB_HOST', getEnvVar('WORDPRESS_DB_HOST'));
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// Dissallow file edit, to prevent people messing with plugins and themes.
define('DISALLOW_FILE_EDIT', true);

$table_prefix = getEnvVar('WORDPRESS_TABLE_PREFIX', 'wp_');
define('WP_DEBUG', getEnvVar('WP_DEBUG', false));

/** Absolute path to the WordPress directory. */
if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}

require_once __DIR__ . '/settings/wp-salt.php';

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );




