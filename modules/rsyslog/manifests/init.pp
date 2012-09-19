class rsyslog {
  $graylog_server = "10.183.170.37"
  package { "rsyslog": ensure => installed }
  service { "rsyslog": ensure => running, require => Package["rsyslog"] }

  file {"/etc/rsyslog.d/graylog":
    ensure => absent,
  }
  
  file {"/etc/rsyslog.d/graylog.conf":
    content => template("rsyslog/graylog.erb"),
    notify => Service["rsyslog"],
    require => Package["rsyslog"],
  }

  file {"/etc/rsyslog.d/template.conf":
    source => "puppet:///modules/rsyslog/template.conf",
    notify => Service["rsyslog"],
    require => Package["rsyslog"],
  }
    
  
}
