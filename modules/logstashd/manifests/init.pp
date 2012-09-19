class logstashd {
  $graylog_server_ip = $graylog_ip
  
  file {"/etc/logstash.d/":
    ensure => "directory",
    owner => "root",
    group => "root",
    mode => 755,
  }
  
  wget::fetch{"logstash":
    source => "http://semicomplete.com/files/logstash/logstash-1.1.0-monolithic.jar",
    destination => "/root/logstash.jar",
  }

  file {"/etc/init.d/logstash":
    source => "puppet:///modules/logstashd/logstash",
    ensure => present,
    mode => 0755,
    owner => root,
    group => root
  }

  file {"/etc/logstash.d/graylog.conf":
    content => template("logstashd/graylog.conf.erb"),
    ensure => present,
    mode => 0644,
    owner => root,
    group => root,
    require => File["/etc/logstash.d"],
  }

  service {"logstash":
    ensure => running,
    subscribe => File["/etc/logstash.d"],
    require => [
                File["/etc/init.d/logstash"],
    File["/etc/logstash.d"],
    Wget::Fetch["logstash"],
    Package["openjdk-6-jre"],
    ]
  }

  define nginx {

    file {"/etc/logstash.d/nginx.conf":
      source => "puppet:///modules/logstashd/nginx.conf",
      ensure => present,
      mode => 0644,
      owner => root,
      group => root,
      require => File["/etc/logstash.d"],
    }
    
  }
}
