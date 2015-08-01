Gem::Specification.new do |gem|
  gem.name        = "refrescar"
  gem.version     = '0.4.0'
  gem.platform    = Gem::Platform::RUBY
  gem.summary     = "Code reloader for Ruby, on Linux."
  gem.description = "Code reloader, implemented using Celluloid and rb-inotify."
  gem.licenses    = ["MIT"]

  gem.authors     = ["digitalextremist //"]
  gem.email       = ["code@extremist.digital"]
  gem.homepage    = "https://github.com/abstractive/refrescar"

  gem.required_ruby_version     = ">= 1.9.2"
  gem.required_rubygems_version = ">= 1.3.6"

  gem.files        = Dir[
                      "README.md",
                      "CHANGES.md",
                      "LICENSE.txt",
                      "lib/**/*"
                    ]

  gem.require_path = "lib"
  gem.add_runtime_dependency 'celluloid', '>= 0.17.0'
  gem.add_runtime_dependency 'rb-inotify'
  gem.add_runtime_dependency "abstractive"
end
