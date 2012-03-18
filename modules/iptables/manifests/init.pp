class iptables {
  file { [ "/root/iptables",
     "/root/iptables/hosts",
     "/root/iptables/roles" ]:
       ensure => directory,
  }

  file { "/root/iptables/roles/common":
    source => "puppet:///modules/iptables/common.role",
    notify => Exec["run-iptables"],
  }

  file { "/root/iptables/names":
    source => "puppet:///modules/iptables/names",
    notify => Exec["run-iptables"],
  }

  file { "/root/iptables/iptables.sh":
    source => "puppet:///modules/iptables/iptables.sh",
    mode   => "755",
    notify => Exec["run-iptables"],
  }

  file { "/root/iptables/hosts/${hostname}":
    content => "export MAIN_IP=${ipaddress}\n",
    replace => false,
    require => File["/root/iptables/hosts"],
    notify  => Exec["run-iptables"],
  }

  exec { "run-iptables":
    cwd         => "/root/iptables",
    command     => "/usr/bin/test -f hosts/${hostname} && /root/iptables/iptables.sh && /sbin/iptables-save >/etc/iptables.rules",
                   refreshonly => true,
  }

  append_if_no_such_line { "restore iptables rules":
    file => "/etc/network/interfaces",
    line => "pre-up iptables-restore < /etc/iptables.rules",
  }

  define role() {
    include iptables
    file { "/root/iptables/roles/${name}":
      source  => "puppet:///modules/iptables/${name}.role",
      replace => false,
      require => File["/root/iptables/roles"],
      notify  => Exec["run-iptables"],
    }
    append_if_no_such_line { "${name} role":
      file    => "/root/iptables/hosts/${hostname}",
      line    => ". `dirname \$0`/roles/${name}",
      require => File["/root/iptables/hosts/${hostname}"],
      notify  => Exec["run-iptables"],
    }
  }
}