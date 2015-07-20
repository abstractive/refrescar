require 'find'
require 'rb-inotify'
require 'abstractive/actor'

class Abstractive::Refrescar < Abstractive::Actor

  def initialize(options={})
    @logger = options[:logger]
    options[:root] ||= Dir.pwd
    @root = Array[options[:root]]
    @debug = options.fetch(:debug, false)
    @announcing = options.fetch(:announcing, true)
    @reschedule = options.fetch(:reschedule, false)
    @after_reload = options.fetch(:after_reload, false)
    @watcher = INotify::Notifier.new
    @events = [
      :close_write,
      #de :modify         #de This seems to fire twice in certain cases. Used :close_write instead.
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

  def reload(file)
    begin
      load(file)
      console("Reloaded: #{file}") if @announcing
    	@watcher.watch(file, *@events) { reload file } if @reschedule
    	@after_reload.call(file) if @after_reload.is_a? Proc
    rescue SyntaxError => ex
      exception(ex, "Code Reloading > Syntax error in #{file}")
    rescue LoadError => ex
      exception(ex, "Code Reloading > Missing file: #{file}")
    end
  rescue => ex
    exception(ex, "Trouble reloading file: #{file}")
  end

end

