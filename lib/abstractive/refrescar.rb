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
      @on_reload = block
      @watcher = INotify::Notifier.new
      @root.each { |r|
        Find.find( r ) { |e|
          if !File.extname(e) == '.rb' and !File.directory? e
            Find.prune
          else
            begin
              if File.extname(e) == '.rb'
                debug("Will reload: #{e}") if @debug
                @watcher.watch(e, :modify) { async.reload(e) }
              end
            rescue
            end
          end
        }
      }
      async.reloading
    end

    def reloading
      debug("Started code reloading...") if @debug
      @watcher.run
    rescue => ex
      exception(ex, "Trouble running reloader.")
      raise
    end

    [:debug, :console, :exception].each { |m|
      define_method(m) { |*args|
        if @logger and @logger.respond_to?(m)
          @logger.send(m, *args)
        else
          puts *args
        end
      }
    }

    def reload!(file)
      begin
        load(file)
        debug("Reloaded: #{file}") if @debug
      rescue SyntaxError => ex
        exception(ex, "Code Reloading > Syntax error in #{file}")
      rescue LoadError => ex
        exception(ex, "Code Reloading > Missing file: #{file}")
      rescue => ex
        exception(ex, "Code Reloading > Problem reloading file: #{file}")
      end
    end

    def reload(file)
      debug("Reloading: #{file}") if @debug
      reload!(file)
      @watcher.watch( file, :modify) { reload file }
      @on_reload.call(file) if @on_reload.is_a? Proc
    rescue => ex
      exception(ex, "Trouble reloading file.")
      raise
    end

  end
end
