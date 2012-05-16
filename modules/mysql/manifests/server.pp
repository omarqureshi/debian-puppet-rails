class mysql::server {
  package { "mysql-server": ensure => installed }
  package { "sphinxsearch": ensure => installed }

  service { "mysql":
    enable => true,
    ensure => running,
    require => Package["mysql-server"],
  }

  file { "/etc/mysql/my.cnf":
    content => template("mysql/my.cnf.erb"),
    owner   => "mysql", group => "mysql",
    notify  => Service["mysql"],
    require => Package["mysql-server"],
  }

  exec { "set-mysql-password":
    unless => "/usr/bin/mysqladmin -uroot -p${mysql_password} status",
    command => "/usr/bin/mysqladmin -uroot password ${mysql_password}",
    require => Service["mysql"],
  } 
}