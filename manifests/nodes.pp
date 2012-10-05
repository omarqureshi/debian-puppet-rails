Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
stage { 'first': before => Stage['main'] }
stage { 'last': require => Stage['main'] }

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
      { hostname => "db.production.translator.edisonnation.com", ip => "10.183.32.243"},
      { hostname => "app.production.translator.edisonnation.com", ip => "10.183.37.2"},
      { hostname => "app1.production.edisonnation.com", ip => "10.176.42.95" },
      { hostname => "app2.production.edisonnation.com", ip => "10.176.42.155" },
      { hostname => "app3.production.edisonnation.com", ip => "10.183.162.189" },
      { hostname => "db.production.edisonnation.com", ip => "10.176.42.86" },
      { hostname => "cache.production.edisonnation.com", ip => "10.183.173.51" },
      { hostname => "jobs.production.edisonnation.com", ip => "10.183.170.51" },
      { hostname => "assets.production.edisonnation.com", ip => "10.183.173.1" },
      { hostname => "logs.edisonnation.com", ip => "10.183.170.37" },
    ],
  }
}

node basenode {
  class {"apt":}
  include "backports"
  include "debian-pre"
  include "common"
  include "rvm"
  package {"augeas-lenses": ensure => absent }
  package {"augeas-tools": ensure => absent }
  package {"libaugeas-dev": ensure => absent }
  package {"libaugeas-ruby1.8": ensure => absent }
  package {"libaugeas0": ensure => absent }
  package {"pkg-config": ensure => installed }
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
  include "git"
  git::repo {'emacs-config':
    target => '/etc/emacs.d',
    source => 'git://github.com/omarqureshi/emacs-config.git',
    user   => 'root',
    require => Package["emacs-snapshot"]
  }
  file { "/etc/emacs.d":
    mode => "777",
    require => Git::Repo["emacs-config"],
    recurse => true,
  }
  file { '/root/.emacs.d':
    ensure => link,
    target => '/etc/emacs.d',
    force => true,
  }
  file { '/home/www/.emacs.d':
    ensure => link,
    target => '/etc/emacs.d',
    force => true,
  }
  include 'ssh_keys'
  include 'bash_profile'
  file {"/var/www":
    ensure => "directory",
    owner => "www",
    group => "www",
    mode => 750,
  }
  package {"openjdk-6-jre": ensure => installed }
}

node 'en-logs' inherits 'ruby-193' {
  class {"mongodb": auth => true }
  wget::fetch {"elasticsearch":
    source => "https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.19.8.deb",
    destination => "/root/elasticsearch.deb",
  }
  package {"elasticsearch":
    ensure => installed,
    provider => dpkg,
    source => "/root/elasticsearch.deb",
    require => Wget::Fetch["elasticsearch"],
  }
  service {"elasticsearch":
    ensure => running,
    require => Package["elasticsearch"]
  }
  
  class {'graylog': dirname => 'logs.edisonnation.com', www_user => "www" }
  iptables::role { "graylog": }
  nginx::unicorn_app { 'logs.edisonnation.com':
    require => Class["graylog"],
  }
  nginx::unicorn_site { 'logs.edisonnation.com': 
    domain => 'logs.edisonnation.com',
    dirname => 'logs.edisonnation.com'
  }
  rvm_gemset {
    "ruby-1.9.3-p194@graylog":
      ensure => present,
      require => Rvm_system_ruby['1.9.3-p194'],
  }
  rvm_gem {
    'ruby-1.9.3-p194@graylog/unicorn':
      ensure => latest,
      require => [Rvm_system_ruby['1.9.3-p194'], Rvm_gemset["ruby-1.9.3-p194@graylog"]]
  }
  class {"graylog_god_wrapper": role => "app", env => "production" }
  env_setup::rails_env { 'production': }
  env_setup::role { 'app': }
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
   '1.9.3-p194': 
     ensure => 'present',
     default_use => true,
  }
  rvm_gem {
    'ruby-1.9.3-p194@global/bundler':
      ensure => latest,
      require => Rvm_system_ruby['1.9.3-p194'],
  }
}

node 'translator' inherits 'ruby-193' {
  rvm_gemset {
    "ruby-1.9.3-p194@translator":
      ensure => present,
      require => Rvm_system_ruby['1.9.3-p194'],
  }
  rvm_gem {
    'ruby-1.9.3-p194@translator/unicorn':
      ensure => latest,
      require => [Rvm_system_ruby['1.9.3-p194'], Rvm_gemset["ruby-1.9.3-p194@translator"]]
  }
}

node 'translator-prod-db' inherits 'translator' {
  class {'postgresql::debian::v9-1::repo': }
  class {'postgresql::debian::v9-1::server': stage => 'last' }
  class {'translator-production-postgresql-config': stage => 'last'}

  class {'www-postgres-user': stage => "last"}
  iptables::role { "pg-server": }
  env_setup::role { "db": }
  env_setup::rails_env { 'production': }
  class {"translator_god_wrapper": role => "db", env => "production" }
}

node 'translator-prod-app' inherits 'translator' {
  class {'postgresql::debian::v9-1::repo': }
  class {'postgresql::debian::v9-1::client': stage => 'last' }
  nginx::unicorn_site { 'translator.edisonnation.com': 
    domain => 'translator.edisonnation.com',
    dirname => 'translator.edisonnation.com'
  }
  
  iptables::role { "web-server": }
  nginx::unicorn_app { 'translator.edisonnation.com': }
  env_setup::role { 'app': }
  env_setup::rails_env { 'production': }
  class {"translator_god_wrapper": role => "app", env => "production" }
}

node 'en-tesla' inherits 'ruby-187' {
  rvm_gemset {
    "ruby-1.8.7-p358@tesla":
      ensure => present,
      require => Rvm_system_ruby['1.8.7-p358'],
  }
  package {"imagemagick": ensure => installed }
  package {"libmysqlclient-dev": ensure => installed }
  package {"libmagick9-dev": ensure => installed }
  rvm_gem {
    'ruby-1.8.7-p358@tesla/unicorn':
      ensure => latest,
      require => [Rvm_system_ruby['1.8.7-p358'], Rvm_gemset["ruby-1.8.7-p358@tesla"]]
  }
  logrotate::file {"tesla-rails":
    log => "/var/www/edisonnation.com/current/log/*.log",
    options => ["daily", "size 100M", "missingok", "rotate 15", "compress", "delaycompress", "notifempty", "copytruncate"]
  }
  include 'rsyslog'
  include 'wkhtmltopdf'
}

node 'en-tesla-ci' inherits 'en-tesla' {
  nginx::jenkins_site { 'edisonnation.com':
    passwdloc => 'en-staging', 
  }
  include mysql::server
  include jenkins
  iptables::role { "web-server": }
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
  iptables::role { "web-server": }
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
  rvm_gem {
    'ruby-1.8.7-p358@tesla/aws-sdk':
      ensure => latest,
      require => [Rvm_system_ruby['1.8.7-p358'], Rvm_gemset["ruby-1.8.7-p358@tesla"]]
  }
  include 'logstashd'
  logstashd::nginx {"nginx": }
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
    sslloc => 'en-medical', 
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
  iptables::role { "web-server": }
}

node 'en-staging-assets' inherits 'en-assets' {
  nginx::assets_site { 'edisonnation.com': sslloc => 'en-staging' }
  class {"tesla_god_wrapper": role => "file", env => "staging" }
  env_setup::rails_env { 'staging': }
}

node 'en-dev-assets' inherits 'en-assets' {
  nginx::assets_site { 'edisonnation.com': sslloc => 'en-staging' }
  class {"tesla_god_wrapper": role => "file", env => "development" }
  env_setup::rails_env { 'development': }
}

node 'id-blog' {
  include ssh
}

node 'en-production-db' inherits 'en-db' {
  class {"tesla_god_wrapper": role => "db", env => "production" }
  env_setup::rails_env { 'production': }
}

node 'en-production-app' inherits 'en-app' {
  class {"tesla_god_wrapper": role => "app", env => "production" }
  env_setup::rails_env { 'production': }
}

node 'en-production-app1' inherits 'en-production-app' {
    nginx::unicorn_site { 'www.edisonnation.com': 
    assethost => 'assets.production.edisonnation.com', 
    domain => 'www.edisonnation.com',
    dirname => 'edisonnation.com',
    sslloc => 'en.com' }
    nginx::add_redirect { 'edisonnation.com': redirect => 'www.edisonnation.com' }
}

node 'en-production-app3' inherits 'en-production-app' {
    nginx::unicorn_site { 'www.edisonnation.com': 
    assethost => 'assets.production.edisonnation.com', 
    domain => 'www.edisonnation.com',
    dirname => 'edisonnation.com',
    sslloc => 'en.com' }
    nginx::add_redirect { 'edisonnation.com': redirect => 'www.edisonnation.com' }
}

node 'en-production-app2' inherits 'en-production-app' {
    nginx::unicorn_site { 'edisonnationmedical.com': 
    assethost => 'assets.production.edisonnation.com',
    domain => 'edisonnationmedical.com',
    sslloc => 'en-medical',  
    dirname => 'edisonnationmedical.com' }
    nginx::add_redirect { 'www.edisonnationmedical.com': redirect => 'edisonnationmedical.com' }
}

node 'en-production-assets' inherits 'en-assets' {
  nginx::assets_site { 'edisonnation.com': sslloc => 'en.com' }
  class {"tesla_god_wrapper": role => "file", env => "production" }
  env_setup::rails_env { 'production': }
}

node 'en-production-jobs' inherits 'en-jobs' {
  class {"tesla_god_wrapper": role => "job", env => "production" }
  env_setup::rails_env { 'production': }
}

node 'en-production-cache' inherits 'en-cache' {
  class {"memcached": memory => '128'}
  class {"tesla_god_wrapper": role => "cache", env => "production" }
  env_setup::rails_env { 'production': }
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

class translator_god_wrapper($role, $env) {
  class { "god":
     role => $role,
     rails_environment => $env,
     ruby => "1.9.3-p194",
     gemset => "translator",
     ruby_type => "ruby",
     project => "translator.edisonnation.com",
  }  
}

class graylog_god_wrapper($role, $env) {
  class { "god":
     role => $role,
     rails_environment => $env,
     ruby => "1.9.3-p194",
     gemset => "graylog",
     ruby_type => "ruby",
     project => "logs.edisonnation.com",
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
