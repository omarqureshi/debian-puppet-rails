class graylog($dirname, $www_user, $graylog_ver="0.9.6p1") {
  
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

  file {"/var/www/${dirname}":
    ensure => directory,
    require => [File["/var/www"], Exec["untar_graylog_${graylog_ver}"]],
    owner => $www_user,
    group => $www_user,
  }

  file {"/var/www/${dirname}/current":
    ensure => link,
    target => "/root/graylog2-web-interface-${graylog_ver}",
    require => File["/var/www/${dirname}"],
  }

  file {"/var/www/${dirname}/shared":
    ensure => directory,
    require => File["/var/www/${dirname}"],
    owner => $www_user,
    group => $www_user,
  }

  file {"/var/www/${dirname}/shared/log":
    ensure => directory,
    require => File["/var/www/${dirname}/shared"],
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/log":
    ensure => link,
    target => "/var/www/${dirname}/shared/log",
  }

  file {"/var/www/${dirname}/shared/pids":
    ensure => directory,
    require => File["/var/www/${dirname}/shared"],
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/shared/tmp":
    ensure => directory,
    require => File["/var/www/${dirname}/shared"],
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/shared/tmp/sockets":
    ensure => directory,
    require => File["/var/www/${dirname}/shared/tmp"],
    owner => $www_user,
    group => $www_user,    
  }



  file {"/var/www/${dirname}/current/config/god":
    ensure => directory,
    require => File["/var/www/${dirname}/current"],
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/god/configs":
    ensure => directory,
    require => File["/var/www/${dirname}/current/config/god"],
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/god/production":
    ensure => directory,
    require => File["/var/www/${dirname}/current/config/god"],
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/god/production/app-server":
    ensure => directory,
    require => File["/var/www/${dirname}/current/config/god/production"],
    owner => $www_user,
    group => $www_user,    
  }


  file {"/var/www/${dirname}/current/config/god/configs/unicorn.god":
    require => File["/var/www/${dirname}/current/config/god/configs"],
    source => "puppet:///modules/graylog/unicorn.god",
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/unicorn.rb":
    require => File["/var/www/${dirname}/current"],
    source => "puppet:///modules/graylog/unicorn.rb",
    owner => $www_user,
    group => $www_user,    
  }


  file {"/var/www/${dirname}/current/config/god/configs/nginx.god":
    require => File["/var/www/${dirname}/current/config/god/configs"],
    source => "puppet:///modules/graylog/nginx.god",
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/god/configs/contacts.rb":
    require => File["/var/www/${dirname}/current/config/god/configs"],
    source => "puppet:///modules/graylog/contacts.rb",
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/god/production/app-server/all.god":
    require => File["/var/www/${dirname}/current/config/god/production/app-server"],
    source => "puppet:///modules/graylog/application.god",
    owner => $www_user,
    group => $www_user,    
  }

  file {"/var/www/${dirname}/current/config/mongoid.yml":
    require => File["/var/www/${dirname}/current"],
    source => "puppet:///modules/graylog/mongoid.yml",
    owner => $www_user,
    group => $www_user,    
  }


  file {"/var/www/${dirname}/current/.rvmrc":
    require => File["/var/www/${dirname}/current"],
    content => "rvm 1.9.3@graylog",
    owner => $www_user,
    group => $www_user,
  }

  cron::create {"send-subscriptions":
    interval => "daily",
    script => "#!/bin/bash
source /etc/profile.d/rails_env
source \"/usr/local/rvm/scripts/rvm\"
rvm 1.9.3@graylog
cd /var/www/${dirname}/current
bundle exec rake RAILS_ENV=production subscriptions:send"
  }

}
