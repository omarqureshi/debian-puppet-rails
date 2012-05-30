Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

node 'en-puppet' inherits basenode {
  class { "dnsmasq": 
    hosts => [ 
      { hostname => "puppet.edisonnation.com", ip => "10.176.71.36" },
      { hostname => "assets.staging.edisonnation.com", ip => "10.183.173.231" },
      { hostname => "cache.staging.edisonnation.com", ip => "10.183.173.12" },
      { hostname => "jobs.staging.edisonnation.com", ip => "10.183.170.224" },
      { hostname => "app.staging.edisonnation.com", ip => "10.183.173.128" },
      { hostname => "db.staging.edisonnation.com", ip => "10.183.169.227"},
      { hostname => "app.1.staging.edisonnation.com", ip => "10.183.173.177"},
      { hostname => "app.dev.edisonnation.com", ip => "10.183.170.170"},
      { hostname => "db.dev.edisonnation.com", ip => "10.183.170.140"},
      { hostname => "assets.dev.edisonnation.com", ip => "10.183.160.83"},
      { hostname => "cache.dev.edisonnation.com", ip => "10.183.170.179"},
      { hostname => "jobs.dev.edisonnation.com", ip => "10.183.173.58"},
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
  package {"inotify-tools": ensure => installed }
  package {"htop": ensure => installed }
  package {"sendmail": ensure => installed, require => Package["sendmail-bin"] }
  include "emacs"
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
      require => [Rvm_system_ruby['1.8.7-p358'], Rvm_gemset["ruby-1.8.7-p358@tesla"]]
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
  env_setup::role { "db": }
}

node 'en-staging-db' inherits 'en-db' { 
  class {"tesla_god_wrapper": role => "db", env => "staging" }
  env_setup::rails_env { 'staging': }
}

node 'en-dev-db' inherits 'en-db' {
  class {"tesla_god_wrapper": role => "db", env => "development" }
  env_setup::rails_env { 'development': }
}

node 'en-jobs' inherits 'en-tesla' {
  env_setup::role { "jobs": }
}

node 'en-staging-jobs' inherits 'en-jobs' {
  class {"tesla_god_wrapper": role => "job", env => "staging" }
  env_setup::rails_env { 'staging': }
}

node 'en-dev-jobs' inherits 'en-jobs' {
  class {"tesla_god_wrapper": role => "job", env => "development" }
  env_setup::rails_env { "development": }
}

node 'en-app' inherits 'en-tesla' {
  iptables::role { "web-server": }
  nginx::unicorn_app { 'edisonnation.com': }
  env_setup::role { 'app': }
}

node 'en-staging-app' inherits 'en-app' { 
  class {"tesla_god_wrapper": role => "app", env => "staging" }
  nginx::unicorn_site { 'edisonnation.com': 
    assethost => 'assets.staging.edisonnation.com', 
    domain => 'staging.edisonnation.com',
    sslloc => 'en-staging', 
    passwdloc => 'en-staging' }
  nginx::unicorn_site { 'medical.edisonnation.com': 
    assethost => 'assets.staging.edisonnation.com',
    domain => 'medical-staging.edisonnation.com',
    sslloc => 'en-staging', 
    passwdloc => 'en-staging', 
    dirname => 'edisonnation.com' }
  env_setup::rails_env { 'staging': }
}

node 'en-dev-app' inherits 'en-app' {
  class {"tesla_god_wrapper": role => "app", env => "development" }
  nginx::unicorn_site { 'edisonnation.com': 
    assethost => 'assets.dev.edisonnation.com', 
    domain => 'dev.edisonnation.com',
    sslloc => 'en-staging', 
    passwdloc => 'en-staging' }
  nginx::unicorn_site { 'medical.edisonnation.com': 
    assethost => 'assets.dev.edisonnation.com',
    domain => 'medical-dev.edisonnation.com',
    sslloc => 'en-staging', 
    passwdloc => 'en-staging', 
    dirname => 'edisonnation.com' }
  env_setup::rails_env { 'development': }
}

node 'en-cache' inherits 'en-tesla' {
  iptables::role { "memcached-server": }
  env_setup::role { 'cache': } 
}

node 'en-staging-cache' inherits 'en-cache' {
  class {"memcached": memory => '128'}
  class {"tesla_god_wrapper": role => "cache", env => "staging" }
  env_setup::rails_env { 'staging': }
}

node 'en-dev-cache' inherits 'en-cache' {
  class {"memcached": memory => '128'}
  class {"tesla_god_wrapper": role => "cache", env => "development" }
  env_setup::rails_env { 'development': }
}

node 'en-assets' inherits 'en-tesla' {
  env_setup::role { 'assets': }
}

node 'en-staging-assets' inherits 'en-assets' {
  nginx::assets_site { 'edisonnation.com': sslloc => 'en-staging' }
  class {"tesla_god_wrapper": role => "file", env => "staging" }
  env_setup::rails_env { 'staging': }
}

node 'en-dev-assets' inherits 'en-assets' {
  nginx::assets_site { 'edisonnation.com': sslloc => 'en-staging' }
  class {"tesla_god_wrapper": role => "file", env => "staging" }
  env_setup::rails_env { 'development': }
}

node 'id-blog' {
  include ssh
}


class tesla_god_wrapper($role, $env) {
  class { "god":
     role => $role,
     rails_environment => $env,
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
