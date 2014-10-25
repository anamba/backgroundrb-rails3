# see http://refspecs.freestandards.org/LSB_3.1.0/LSB-Core-generic/LSB-Core-generic/iniscrptact.html
# for LSB-compliancy info
module BackgrounDRb
  class StartStop
    def start
      if running? # starting an already running process is considered a success
        puts "BackgrounDRb Already Running"
        exit(0)
      elsif dead? # dead, but pid exists
        File.unlink(PID_FILE)
      end
      
      # status == 3, not running.
      $stdout.sync = true
      print "Starting BackgrounDRb.... "
      start_bdrb
      # TODO: find a way to report success/failure
      puts "Done!"
      exit(0)
    end
    
    def stop
      if running?
        kill_process(PID_FILE)
      else
        puts "BackgrounDRb Not Running"
      end
      
      # pid_files.each do |x|
      #   begin
      #     kill_process(x)
      #   rescue Errno::ESRCH
      #     # stopping an already stopped process is considered a success (exit status 0)
      #   end
      # end
      File.unlink(PID_FILE) if pidfile_exists?
    end
    
    # returns the correct lsb code for the status:
    # 0 program is running or service is OK
    # 1 program is dead and pid file exists
    # 3 program is not running
    def status
      case
        when pidfile_exists? && process_running? then 0
        when pidfile_exists?                     then 1
        else                                          3
      end
    end
    
    def pidfile_exists? ; File.exists?(PID_FILE) ; end
    
    def process_running?
      begin
        Process.kill(0,self.pid)
        true
      rescue Errno::ESRCH
        false
      end
    end
    
    def running? ; status == 0 ; end
    
    # pidfile exists but process isn't running
    def dead? ; status == 1 ; end
    
    def pid
      File.read(PID_FILE).strip.to_i if pidfile_exists?
    end
    
    def start_bdrb
      require "rubygems"
      require "yaml"
      require "erb"
      require "logger"
      require "packet"
      require "optparse"
      
      require "bdrb_config"
      require RAILS_HOME + "/config/boot"
      require "active_support"
      
      BackgrounDRb::Config.parse_cmd_options ARGV
      
      require RAILS_HOME + "/config/environment"
      require "bdrb_job_queue"
      require "backgroundrb_server"
      
      #proper way to daemonize - double fork to ensure parent can have no interest in the grandchild
      if fork                     # Parent exits, child continues.
        sleep(1)
      else
        Process.setsid                   # Become session leader.
        
        op = File.open(PID_FILE, "w")
        op.write(Process.pid().to_s)
        op.close
        
        if BDRB_CONFIG[:backgroundrb][:log].nil? or BDRB_CONFIG[:backgroundrb][:log] != 'foreground'
          redirect_io(SERVER_LOGGER)
        end
        $0 = "backgroundrb master"
        BackgrounDRb::MasterProxy.new()
      end
      
      #File.open(PID_FILE, "w") {|pidfile| pidfile.write(main_pid)}
    end
    
    def kill_process(pid_file)
      pid = File.open(pid_file, "r") { |pid_handle| pid_handle.gets.strip.to_i }
      pgid =  Process.getpgid(pid)
      Process.kill('-TERM', pgid)
      File.delete(pid_file) if File.exists?(pid_file)
      puts "Stopped BackgrounDRb worker with pid #{pid}"
    end
    
    
    # Free file descriptors and
    # point them somewhere sensible
    # STDOUT/STDERR should go to a logfile
    def redirect_io(logfile_name)
      begin; STDIN.reopen "/dev/null"; rescue ::Exception; end
      
      if logfile_name
        begin
          STDOUT.reopen logfile_name, "a"
          STDOUT.sync = true
        rescue ::Exception
          begin; STDOUT.reopen "/dev/null"; rescue ::Exception; end
        end
      else
        begin; STDOUT.reopen "/dev/null"; rescue ::Exception; end
      end
      
      begin; STDERR.reopen STDOUT; rescue ::Exception; end
      STDERR.sync = true
    end
  end

end
