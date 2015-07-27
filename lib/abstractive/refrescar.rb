require 'find'
require 'rb-inotify'
require 'abstractive/actor'

class Abstractive::Refrescar < Abstractive::Actor

  def initialize(options={})
    @running = false
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
    start unless options.fetch(:autostart, false)
  end

  def add(root, relative=nil)
    root = File.expand_path(root, relative) if relative
    @root << root
    set_watchers(root) if @running
  end

  def reloading
    @root.each { |root| set_watchers(root) }
    debug("Started code reloading...") if @debug
    @running = true
    @watcher.run
  rescue => ex
    exception(ex, "Trouble running reloader.")
    raise
  end

  def start
    async.reloading
  end

  def set_watchers(path)
    debug("Watching path: #{path}") if @debug
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
  end

  def reload(file)
    begin
      load(file)
      console("Reloaded: #{file}") if @announcing
    	@watcher.watch(file, *@events) { reload file } if @reschedule
    	@after_reload.call(file) if @after_reload.is_a? Proc
    rescue SyntaxError => ex
      exception(ex, "Code Reloading > Syntax error in #{file}", console: false)
    rescue LoadError => ex
      exception(ex, "Code Reloading > Missing file: #{file}", console: false)
    end
  rescue => ex
    exception(ex, "Trouble reloading file: #{file}", console: false)
  end

end

