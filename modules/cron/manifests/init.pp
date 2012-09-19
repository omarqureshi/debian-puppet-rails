# manage cron jobs in separate files - call with enable => "false" to delete the job
class cron {
  define create( $enable = "true", $interval = "daily", $script = "", $package = "" ) {
    file { "/etc/cron.$interval/$name":
      content         => $script,
      ensure          => $enable ? {
        "false" => absent,
        default => file,
      },
      force           => true,
      owner           => root,
      group           => root,
      mode            => $interval ? {
        "d"     => 644,
        default => 755,
      },
      require         => $package ? {
        ""      => undef,
        default => Package[$package],
      },
    }
  }
}
