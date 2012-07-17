class logrotate::base {

  package { logrotate:
    ensure => installed,
  }

  file { "/etc/logrotate.d":
    ensure => directory,
    owner => root,
    group => root,
    mode => 755,
    require => Package[logrotate],
  }

}

define logrotate::file( $log, $options, $postrotate = "NONE" ) {

  # $options should be an array containing 1 or more logrotate directives (e.g. missingok, compress)

  include logrotate::base

  file { "/etc/logrotate.d/${name}":
    owner => root,
    group => root,
    mode => 644,
    content => template("logrotate/logrotate.erb"),
    require => File["/etc/logrotate.d"],
  }
}
