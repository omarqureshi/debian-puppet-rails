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
      { hostname => "app.1.staging.edisonnation.com", ip => "10.183.173.177"},
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
  nginx::unicorn_app {'copycopter': }
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

node 'en-staging-db' inherits 'en-db' { 
  env_setup::rails_env { 'staging': }
  env_setup::role { "db": }
}

node 'en-staging-jobs' inherits 'en-tesla' { 
  env_setup::rails_env { 'staging': }
  env_setup::role { "jobs": }
}

node 'en-staging-app' inherits 'en-tesla' { 
  $rails_environment = 'staging'
  include tesla_god_wrapper
  iptables::role { "web-server": }
  nginx::unicorn_app { 'edisonnation.com': }
  nginx::unicorn_site { 'edisonnation.com': 
    assethost => 'assets.staging.edisonnation.com', 
    domain => 'staging.edisonnation.com',
    sslloc => 'en-staging', 
    passwdloc => 'en-staging' }
  nginx::unicorn_site { 'medical.edisonnation.com': 
    assethost => 'staging.edisonnation.com',
    domain => 'medical.staging.edisonnation.com',
    sslloc => 'en-staging', 
    passwdloc => 'en-staging', 
    dirname => 'edisonnation.com' }
  env_setup::rails_env { 'staging': }
  env_setup::role { 'app': }
}

node 'en-staging-cache' inherits 'en-tesla' {
  iptables::role { "memcached-server": }
  class {"memcached": memory => '128'}
  env_setup::rails_env { 'staging': }
  env_setup::role { 'cache': }
}

node 'en-staging-assets' inherits 'en-tesla' {
  $rails_environment = 'staging'
  nginx::assets_site { 'edisonnation.com': sslloc => 'en-staging' }
  include tesla_god_wrapper
  env_setup::rails_env { 'staging': }
  env_setup::role { 'assets': }
}

node 'id-blog' {
  include ssh
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

class copycopter_god_wrapper {
  class { "god": 
     role => "all",
     ruby => "1.9.3-p125",
     gemset => "copycopter",
     ruby_type => "ruby",
     project => "copycopter",
  }
}

class env_setup {

  define rails_env {
    file { '/etc/profile.d/rails_env':
      ensure => present,
      content => "export RAILS_ENV=$name"
    }
  }

  define role {
    file { '/etc/profile.d/role':
      ensure => present,
      content => "export ROLE=$name"
    }
  }
}