God.watch do |w|
  w.name = "unicorn"
  w.interval = 30.seconds # default

  w.uid = 'www'
  w.gid = 'www'

  # unicorn needs to be run from the rails root
  w.start = "cd #{RAILS_ROOT} && bundle exec unicorn_rails -c #{RAILS_ROOT}/config/unicorn.rb -E #{RAILS_ENV} -D"

  # QUIT gracefully shuts down workers
  w.stop = "kill -QUIT `cat #{PID_DIR}/unicorn.pid`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{PID_DIR}/unicorn.pid`"

  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
  w.pid_file = "#{PID_DIR}/unicorn.pid"

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 350.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
      c.notify = {:contacts => ['en_team','campfire_room'], :priority => 1, :category => 'unicorn'}
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 60.percent
      c.times = 5
      c.notify = {:contacts => ['en_team','campfire_room'], :priority => 1, :category => 'unicorn'}
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = {:contacts => ['en_team','campfire_room'], :priority => 1, :category => 'unicorn'}
    end
  end
end