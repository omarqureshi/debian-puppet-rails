Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

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
  package {"sendmail": ensure => installed }
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

node 'ruby-187-web' inherits 'ruby-187' {
  iptables::role { "web-server": }
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
  include 'postgresql::v9-1'
  postgresql::user { 'www': superuser => true, ensure => present, }
  rvm_gemset {
    "ruby-1.9.3-p125@copycopter":
      ensure => present,
      require => Rvm_system_ruby['1.9.3-p125'],
  }
  nginx::unicorn_site { 'copycopter': }
  class { "god": 
     rails_environment => "development",
     role => "all",
     ruby => "1.9.3-p125",
     gemset => "copycopter",
     ruby_type => "ruby",
     project => "copycopter",
  }
}

node 'en-tesla' inherits 'ruby-187-web' {
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
}

node 'en-tesla-ci' inherits 'en-tesla' {
  nginx::jenkins_site { 'edisonnation.com': }
  include mysql::server
  include jenkins
  package {"imagemagick": ensure => installed }
  package {"libmagick9-dev": ensure => installed }
}

node 'en-experimental' inherits 'en-tesla' {
  nginx::unicorn_site { 'edisonnation.com': }
  package {"imagemagick": ensure => installed }
  package {"libmysqlclient-dev": ensure => installed }
  package {"libmagick9-dev": ensure => installed }
  class { "god": 
     rails_environment => "experimental",
     role => "app-server",
     ruby => "1.8.7-p358",
     gemset => "tesla",
     ruby_type => "ruby",
     project => "edisonnation.com",
  }
  rvm_gem {
    'ruby-1.8.7-p358@tesla/unicorn':
      ensure => latest,
      require => Rvm_system_ruby['1.8.7-p358'],
  }

}