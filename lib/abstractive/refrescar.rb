require 'find'
require 'rb-inotify'
require 'celluloid/current'

module Abstractive
  class Refrescar

    include Celluloid

    def initialize(options={}, &block)
      @logger = options[:logger]
      options[:root] ||= Dir.pwd
      @root = Array[options[:root]]
      @debug = options[:debug] || false
      @announcing = options[:announcing] || false
      @reschedule = options[:reschedule] || false
      @on_reload = block
      @watcher = INotify::Notifier.new
      @events = [
        :close_write,
        #de :modify  #de This seems to fire twice in certain cases.
      ]
      async.reloading
    end

    def reloading
      set_watchers
      debug("Started code reloading...") if @debug
      @watcher.run
    rescue => ex
      exception(ex, "Trouble running reloader.")
      raise
    end

    def set_watchers
      @root.each { |path|
        Find.find( path ) { |file|
          if !File.extname(file) == '.rb' and !File.directory? file
            Find.prune
          else
            begin
              if File.extname(file) == '.rb'
                debug("Will reload: #{file}") if @debug
                @watcher.watch(file, *@events) { reload(file) }
              end
            rescue => ex
              exception(ex, "Code Reloading > Trouble setting watchers.")
            end
          end
        }
      }
    end

    [:debug, :console, :exception].each { |m|
      define_method(m) { |*args|
        begin
          if @logger and @logger.respond_to?(m)
            @logger.send(m, *args)
          else
            puts "#{m}: ... #{args}"
          end
        rescue
          puts "#{m}: ... #{args}"
        end
      }
    }

    def reload(file)
      begin
        load(file)
        console("Reloaded: #{file}") if @announcing
      rescue SyntaxError => ex
        exception(ex, "Code Reloading > Syntax error in #{file}")
      rescue LoadError => ex
        exception(ex, "Code Reloading > Missing file: #{file}")
      end
      @watcher.watch(file, *@events) { reload file } if @reschedule
      @on_reload.call(file) if @on_reload.is_a? Proc
    rescue => ex
      exception(ex, "Trouble reloading file: #{file}")
      raise
    end

  end
end
