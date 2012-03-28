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

  define unicorn_site($domain="", $host="") {
    include nginx

    if $vhost_domain == "" {
      $vhost_domain = $ip_address
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
}