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
  file { "/etc/nginx/sites-enabled/default":
    ensure => absent,
  }
  file { "/etc/nginx/sites-available/default":
    ensure => absent,
  }

  define assets_site($user="www", $domain="", $sslloc="") {
    include nginx
    if $domain == "" {
      $vhost_domain = $ipaddress
    } else {
      $vhost_domain = $domain
    }

    if $sslloc == "" {
      $ssl_loc = ""
    } else {
      $ssl_loc = $sslloc
      add_ssl { "assets": ssl_loc => $ssl_loc, keyname => "server", require => Package["nginx"] }
    }

    $username = $user

 
    file { "/etc/nginx/nginx.conf":
             content => template("nginx/nginx.conf.erb"),
             notify  => Exec["reload nginx"],
             require => Package["nginx"],
    }

    file { "/etc/nginx/sites-available/${name}.conf":
             content => template("nginx/assets_vhost.erb"),
             require => Package["nginx"],
    }

    file { "/etc/nginx/sites-enabled/${name}.conf":
             ensure  => link,
             target  => "/etc/nginx/sites-available/${name}.conf",
             require => File["/etc/nginx/sites-available/${name}.conf"],
             notify  => Exec["reload nginx"],
    }

  }

  define unicorn_app($user="www") {
    include nginx
    $username = $user

    file { "/etc/nginx/nginx.conf":
             content => template("nginx/nginx.conf.erb"),
             notify  => Exec["reload nginx"],
             require => Package["nginx"],
    }

    file { "/etc/nginx/sites-available/app.conf":
           content => template("nginx/unicorn_app.erb"),
           require => Package["nginx"],
    }

    file { "/etc/nginx/sites-enabled/app.conf":
             ensure  => link,
             target  => "/etc/nginx/sites-available/app.conf",
             require => File["/etc/nginx/sites-available/app.conf"],
             notify  => Exec["reload nginx"],
    }
  }

  define unicorn_site($domain="", $assethost="", $sslloc="", $passwdloc="", $dirname="") {
    include nginx

    if $dirname == "" {
      $dir_name = $name
    } else {
      $dir_name = $dirname
    }

    if $domain == "" {
      $vhost_domain = $ipaddress
    } else {
      $vhost_domain = $domain
    }

    if $assethost == "" {
      $asset_host = ""
    } else {
      $asset_host = $assethost
    }

    if $sslloc == "" {
      $ssl_loc = ""
    } else {
      $ssl_loc = $sslloc
      $key_name = $name
      add_ssl { $name: ssl_loc => $ssl_loc, keyname => $key_name }
    }

    if $passwdloc == "" {
      $passwd_loc = ""
    } else {
      $passwd_loc = $passwdloc
      $passwd_name = $name
      file { "/etc/nginx/${passwd_name}.passwd": 
        source => "puppet:///modules/nginx/passwd/$passwd_loc/auth_passwd",
        notify => Exec["reload nginx"],
        require => Package["nginx"],
      }
    }

    $username = $user

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

  define jenkins_site($user="www", $passwdloc="") {
    $username = $user
    include nginx

    if $dirname == "" {
      $dir_name = $name
    } else {
      $dir_name = $dirname
    }
    
    if $passwdloc == "" {
      $passwd_loc = ""
    } else {
      $passwd_loc = $passwdloc
      $passwd_name = $name
      file { "/etc/nginx/${passwd_name}.passwd": 
        source => "puppet:///modules/nginx/passwd/$passwd_loc/auth_passwd",
        notify => Exec["reload nginx"],
        require => Package["nginx"],
      }
    }
    

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

    file { "/etc/nginx/nginx.conf":
             content => template("nginx/nginx.conf.erb"),
             notify  => Exec["reload nginx"],
             require => Package["nginx"],
    }



  }

  define add_redirect($redirect) {
    $server_name = $name
    $redirect_location = $redirect

    file {"/etc/nginx/sites-available/redirect_${server_name}.conf":
           content => template("nginx/redirect.erb"),
           require => Package["nginx"],
    }

    file {"/etc/nginx/sites-enabled/redirect_${server_name}.conf":
           ensure => link,
           target => "/etc/nginx/sites-available/redirect_${server_name}.conf",
           require => File["/etc/nginx/sites-available/redirect_${server_name}.conf"],
           notify => Exec["reload nginx"],
    }
  }

  define add_ssl($ssl_loc, $keyname) {
    file { "/etc/nginx/${keyname}.crt":
      source => "puppet:///modules/nginx/ssl/${ssl_loc}/server.crt",
      notify => Exec["reload nginx"],
      require => Package["nginx"],
    }
    file { "/etc/nginx/${keyname}.key":
      source => "puppet:///modules/nginx/ssl/${ssl_loc}/server.key",
      notify => Exec["reload nginx"],
      require => Package["nginx"],
    }
  }
}
