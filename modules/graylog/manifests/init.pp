class graylog {
  $graylog_ver = "0.9.6p1"
  wget::fetch {"graylog2":
    source => "https://github.com/downloads/Graylog2/graylog2-server/graylog2-server-${graylog_ver}.tar.gz",
    destination => "/root/graylog2.tar.gz"
  }
  exec { "untar_graylog":
    command => "tar xzf /root/graylog2.tar.gz",
    creates => "/root/graylog2-server-${graylog_ver}",
    require => Wget::Fetch["graylog2"],
  }

  file { "/etc/graylog2.conf":
    content => template("graylog/graylog2.conf.erb"),
    require => Exec["untar_graylog"],
  }
}
