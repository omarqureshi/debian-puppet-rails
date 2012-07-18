class graylog($_dirname, $_graylog_ver="0.9.6p1") {
  $graylog_ver = $_graylog_ver
  
  wget::fetch {"graylog2":
    source => "https://github.com/downloads/Graylog2/graylog2-server/graylog2-server-${graylog_ver}.tar.gz",
    destination => "/root/graylog2-${graylog_ver}.tar.gz"
  }
  
  exec { "untar_graylog_${graylog_ver}":
    command => "tar xzf /root/graylog2-${graylog_ver}.tar.gz",
    creates => "/root/graylog2-server-${graylog_ver}",
    require => Wget::Fetch["graylog2"],
  }

  file { "/etc/graylog2.conf":
    content => template("graylog/graylog2.conf.erb"),
    require => Exec["untar_graylog_${graylog_ver}"],
  }

  wget::fetch {"graylog2-web":
    source => "https://github.com/downloads/Graylog2/graylog2-web-interface/graylog2-web-interface-${graylog_ver}.tar.gz",
    require => File["/etc/graylog2.conf"],
    destination => "/root/graylog2-web-${graylog_ver}.tar.gz",
  }

  exec {"untar_graylog_web_${graylog_ver}":
    command => "tar xzf /root/graylog2-web-${graylog_ver}.tar.gz",
    creates => "/root/graylog2-web-interface-${graylog_ver}",
    require => Wget::Fetch["graylog2"],
  }

  file {"/var/www/${_dirname}":
    ensure => directory,
    require => [File["/var/www"], Exec["untar_graylog_${graylog_ver}"]],
  }

  file {"/var/www/${_dirname}/current":
    ensure => link,
    target => "/root/graylog2-web-interface-${graylog_ver}",
    require => File["/var/www/${_dirname}"],
  }

  file {"/var/www/${_dirname}/logs":
    ensure => directory,
    require => File["/var/www/${_dirname}/current"],
  }

  file {"/var/www/${_dirname}/current/config/god":
    ensure => directory,
    require => File["/var/www/${_dirname}/current"],
  }

  file {"/var/www/${_dirname}/config/god/configs":
    ensure => directory,
    require => File["/var/www/${_dirname}/current/config/god"],
  }

  file {"/var/www/${_dirname}/config/god/production":
    ensure => directory,
    require => File["/var/www/${_dirname}/current/config/god"],
  }

  file {"/var/www/${_dirname}/config/god/production/app-server":
    ensure => directory,
    require => File["/var/www/${_dirname}/current/config/god/production"],
  }


  file {"/var/www/${_dirname}/config/god/configs/unicorn.god":
    require => File["/var/www/${_dirname}/current/config/god/configs"],
    source => "puppet:///modules/graylog/unicorn.god",
  }

  file {"/var/www/${_dirname}/config/god/configs/nginx.god":
    require => File["/var/www/${_dirname}/current/config/god/configs"],
    source => "puppet:///modules/graylog/nginx.god",
  }

  file {"/var/www/${_dirname}/config/god/configs/contacts.rb":
    require => File["/var/www/${_dirname}/current/config/god/configs"],
    source => "puppet:///modules/graylog/contacts.rb",
  }

  file {"/var/www/${_dirname}/config/god/production/app-server/all.god":
    require => File["/var/www/${_dirname}/current/config/god/production"],
    source => "puppet:///modules/graylog/all.god",
  }

}
