Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

node 'en-puppet' {
  class { "dnsmasq": 
    hosts => [ 
      { hostname => "puppet.edisonnation.com", ip => "10.176.71.36" },
      { hostname => "assets.staging.edisonnation.com", ip => "10.183.173.231" },
      { hostname => "cache.staging.edisonnation.com", ip => "10.183.173.12" },
      { hostname => "jobs.staging.edisonnation.com", ip => "10.183.170.224" },
      { hostname => "app.staging.edisonnation.com", ip => "10.183.173.128" },
      { hostname => "db.staging.edisonnation.com", ip => "10.183.169.227"},
    ],
  }
}

node basenode {
  include "apt"
  include "backports"
  include "debian-pre"
  include "common"
  include "rvm"
  include "augeas"
  rvm_system_ruby {
   'ree-1.8.7-2012.02': 
     ensure => 'present',
     default_use => false,
  }
  package {"sendmail-bin": ensure => installed }
  package {"sendmail": ensure => installed, require => Package["sendmail-bin"] }
}

node 'ruby-187' inherits basenode {
  rvm_system_ruby {
    '1.8.7-p358':
      ensure => 'present',
      default_use => true,
  }
  rvm_gem {
    'ruby-1.8.7-p358@global/bundler':
      ensure => latest,
      require => Rvm_system_ruby['1.8.7-p358'],
  } 
}

node 'ruby-193' inherits basenode {
  rvm_system_ruby {
   '1.9.3-p125': 
     ensure => 'present',
     default_use => true,
  }
  rvm_gem {
    'ruby-1.9.3-p125@global/bundler':
      ensure => latest,
      require => Rvm_system_ruby['1.9.3-p125'],
  }
}

node 'ruby-193-web' inherits 'ruby-193' {
  iptables::role { "web-server": }
}

node 'en-copycopter' inherits 'ruby-193-web' {
  $rails_environment = 'development'
  include 'postgresql::v9-1'
  postgresql::user { 'www': superuser => true, ensure => present, }
  rvm_gemset {
    "ruby-1.9.3-p125@copycopter":
      ensure => present,
      require => Rvm_system_ruby['1.9.3-p125'],
  }
  nginx::unicorn_site { 'copycopter': }
  include copycopter_god_wrapper
}

node 'en-tesla' inherits 'ruby-187' {
  rvm_gemset {
    "ruby-1.8.7-p358@tesla":
      ensure => present,
      require => Rvm_system_ruby['1.8.7-p358'],
  }
  file {"/var/www":
    ensure => "directory",
    owner => "www",
    group => "www",
    mode => 750,
  }
  package {"imagemagick": ensure => installed }
  package {"libmysqlclient-dev": ensure => installed }
  package {"libmagick9-dev": ensure => installed }
  rvm_gem {
    'ruby-1.8.7-p358@tesla/unicorn':
      ensure => latest,
      require => Rvm_system_ruby['1.8.7-p358'],
  }
}

node 'en-tesla-ci' inherits 'en-tesla' {
  nginx::jenkins_site { 'edisonnation.com': }
  include mysql::server
  include jenkins
  package {"imagemagick": ensure => installed }
  package {"libmagick9-dev": ensure => installed }
}

node 'en-db' inherits 'en-tesla' {
  include mysql::server
  iptables::role { "db-server": }
}

node 'en-staging-db' inherits 'en-db' { }
node 'en-staging-jobs' inherits 'en-tesla' { }

node 'en-staging-app' inherits 'en-tesla' { 
  $rails_environment = 'staging'
  include tesla_god_wrapper
  $assethost = '173.45.227.152'
  include tesla_unicorn_wrapper
  iptables::role { "web-server": }
}

node 'en-staging-cache' inherits 'en-tesla' {
  class {"memcached": memory => '128'}
}

node 'en-staging-assets' inherits 'en-tesla' {
  $rails_environment = 'staging'
  nginx::assets_site { 'edisonnation.com': }
  include tesla_god_wrapper
}

class tesla_god_wrapper {
  class { "god":
     role => "app-server",
     ruby => "1.8.7-p358",
     gemset => "tesla",
     ruby_type => "ruby",
     project => "edisonnation.com",
  }  
}

class tesla_unicorn_wrapper {
  nginx::unicorn_site { 'edisonnation.com': }
}

class copycopter_god_wrapper {
  class { "god": 
     role => "all",
     ruby => "1.9.3-p125",
     gemset => "copycopter",
     ruby_type => "ruby",
     project => "copycopter",
  }
}