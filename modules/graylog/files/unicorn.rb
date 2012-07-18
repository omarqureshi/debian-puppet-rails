worker_processes 2
working_directory "/var/www/logs.edisonnation.com/current"

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true

# Restart any workers that haven't responded in 30 seconds
timeout 30

# Listen on a Unix data socket
listen '/var/www/logs.edisonnation.com/shared/tmp/sockets/unicorn.sock', :backlog => 64

# feel free to point this anywhere accessible on the filesystem
pid "/var/www/logs.edisonnation.com/shared/pids/unicorn.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, ome applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path "/var/www/logs.edisonnation.com/shared/log/unicorn.stderr.log"
stdout_path "/var/www/logs.edisonnation.com/shared/log/unicorn.stdout.log"

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  old_pid = '/var/www/logs.edisonnation.com/shared/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  # Reconnect memcached
  #if Rails.cache.is_a?(ActiveSupport::Cache::MemCacheStore)
  #Rails.cache.instance_variable_get(:@data).reset
  #end
end

# before_exec do |server|
#   paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
#   paths.unshift "#{shared_bundler_gems_path}/bin"
#   ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

#   ENV['GEM_HOME'] = ENV['GEM_PATH'] = shared_bundler_gems_path
#   ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
# end
