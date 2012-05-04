class nginx {
  package {"nginx": ensure => installed}
  service {"nginx":
    enable => true,
    ensure => running,
    require => Package["nginx"]
  }
  exec { "reload nginx":
    command     => "/usr/sbin/service nginx reload",
    require     => Package["nginx"],
    refreshonly => true,
  }
  file { "/etc/nginx/nginx.conf":
    source  => "puppet:///modules/nginx/nginx.conf",
    notify  => Exec["reload nginx"],
    require => Package["nginx"],
  }
  file { "/etc/nginx/sites-enabled/default":
    ensure => absent,
  }
  file { "/etc/nginx/sites-available/default":
    ensure => absent,
  }

  define unicorn_site($domain="", $host="") {
    include nginx

    if $domain == "" {
      $vhost_domain = $ipaddress
    } else {
      $vhost_domain = $domain
    }

    if $host == "" {
      $asset_host = ""
    } else {
      $asset_host = $host
    }

    file { "/etc/nginx/sites-available/${name}.conf":
             content => template("nginx/unicorn_vhost.erb"),
             require => Package["nginx"],
    }

    file { "/etc/nginx/sites-enabled/${name}.conf":
             ensure  => link,
             target  => "/etc/nginx/sites-available/${name}.conf",
             require => File["/etc/nginx/sites-available/${name}.conf"],
             notify  => Exec["reload nginx"],
    }

  }

  define jenkins_site {
    include nginx
    file { "/etc/nginx/sites-available/jenkins.conf":
             content => template("nginx/jenkins_vhost.erb"),
             require => Package["nginx"],
    }

    file { "/etc/nginx/sites-enabled/jenkins.conf":
             ensure  => link,
             target  => "/etc/nginx/sites-available/jenkins.conf",
             require => File["/etc/nginx/sites-available/jenkins.conf"],
             notify  => Exec["reload nginx"],
    }

  }
}