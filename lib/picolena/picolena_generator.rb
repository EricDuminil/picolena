require 'tempfile'
require 'fileutils'
require 'pathname'

class PicolenaGenerator < RubiGen::Base #:nodoc:
  
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])
  
  default_options :destination => 'picolena'
  
  attr_reader :name
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty? and !options[:spec_only]
    @destination_root = options[:destination]

    @directories_to_index=ARGV.collect{|relative_path|
      abs_dir=Pathname.new(relative_path).realpath.to_s
      "\"#{abs_dir}\" : \"#{abs_dir}\""
    }.join("\n  ")
    
    extract_options
  end

  def manifest
    script_options     = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] }
    
    record do |m|
      #Create base dir
      m.directory ''
      
      # Picolena file structure, without any plugin.
      BASEDIRS.each { |path|
        # Ensure appropriate folder exists
        m.directory path
        # Copy every file included in BASEDIRS
        m.folder path, path
      }
      
      # Moved plugins away so they don't get parsed by rdoc/ri.
      RAILS_PLUGINS.each{ |path|
        plugin_source = '../../../rails_plugins/'+path
        plugin_dest   = 'vendor/plugins/'+path
        # Ensure appropriate folder exists
        m.directory plugin_dest
        # Ensure appropriate folder exists
        m.folder plugin_source, plugin_dest
      }

      # Copy every Rails script with exec persmissions.
      m.directory 'script'
      m.directory 'script/performance'
      m.directory 'script/process'
      %w( about breakpointer console destroy generate performance/benchmarker performance/profiler performance/request process/reaper process/spawner process/inspector runner server plugin spec spec_server).each do |file|
        m.file "script/#{file}", "script/#{file}", script_options
      end
      
      # Picolena configuration files
      m.file '../config/white_list_ip.yml', 'config/white_list_ip.yml'
      m.template '../config/indexed_directories.yml', 'config/indexed_directories.yml', :assigns => {:directories_to_index => @directories_to_index}
      m.template '../config/custom_localization.yml', 'lang/ui/custom_localization.yml', :assigns => {:version => Picolena::VERSION::STRING}

      # README, License & Rakefile
      m.file 'MIT-LICENSE', 'LICENSE'
      m.file '../../../README.txt', 'README'
      m.file 'Rakefile', 'Rakefile'
     
      unless options[:no_index]
        # Indexing documents for development environment
        m.rake 'index:create' 
        # Mirroring Ferret development index instead of indexing documents again for production.
        m.mirror 'tmp/ferret_indexes/development', 'tmp/ferret_indexes/production'
      end

      # Launching specs
      m.rake 'spec' unless options[:no_spec]

      # Cleaning up temp folder if --spec-only
      m.clean if options[:spec_only]
    end
  end

  protected
    def banner
      <<-EOS
Creates a documents search engine

USAGE: #{spec.name} directory_to_be_indexed and_other_dirs_if_you_want
EOS
    end

    def add_options!(opts)
      opts.separator ''
      opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |options[:author]| }
      opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
      opts.on("-d", "--destination=path", "Specify destination path (default: 'picolena')"){|options[:destination]|}
      opts.on(nil, "--no-spec", "Install picolena without launching specs."){options[:no_spec]=true}
      opts.on(nil, "--no-index", "Install picolena without indexing documents."){options[:no_index]=true}
      opts.on(nil, "--spec-only", "Test picolena framework without installing it."){
        options[:spec_only]=true
        options[:no_index]=true
        options[:destination]=File.join(Dir::tmpdir,"picolena_test_#{Time.now.to_i}") 
      }
    end
    
    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
    app/controllers
    app/helpers
    app/models
    app/views
    app/views/documents
    app/views/layouts
    config
    config/environments
    config/initializers
    lang/ui
    lib
    lib/filters
    lib/tasks
    log
    public
    public/help
    public/images
    public/images/icons
    public/javascripts
    public/stylesheets
    spec
    spec/controllers
    spec/fixtures
    spec/helpers
    spec/models
    spec/test_dirs
    spec/test_dirs/empty_folder
    spec/test_dirs/indexed
    spec/test_dirs/indexed/basic
    spec/test_dirs/indexed/different_encodings
    spec/test_dirs/indexed/just_one_doc
    spec/test_dirs/indexed/literature
    spec/test_dirs/indexed/others
    spec/test_dirs/indexed/others/nested
    spec/test_dirs/indexed/yet_another_dir
    spec/test_dirs/not_indexed
    spec/views
    spec/views/application
    tmp/cache
    tmp/ferret_indexes
    tmp/pids
    tmp/sessions
    tmp/sockets
    )
    
    RAILS_PLUGINS=%w(
    globalite
    globalite/data
    globalite/lang
    globalite/lang/rails
    globalite/lib
    globalite/lib/globalite
    globalite/lib/rails
    globalite/rdoc
    globalite/rdoc/classes
    globalite/rdoc/classes/ActionView
    globalite/rdoc/classes/ActionView/Helpers
    globalite/rdoc/classes/ActiveRecord
    globalite/rdoc/classes/Globalite
    globalite/rdoc/files
    globalite/rdoc/files/lib
    globalite/rdoc/files/lib/globalite
    globalite/rdoc/files/lib/rails
    globalite/spec
    globalite/spec/helpers
    globalite/spec/lang
    globalite/spec/lang/rails
    globalite/spec/lang/ui
    globalite/tasks
    haml
    rspec
    rspec/autotest
    rspec/bin
    rspec/examples
    rspec/examples/pure
    rspec/examples/stories
    rspec/examples/stories/game-of-life
    rspec/examples/stories/game-of-life/behaviour
    rspec/examples/stories/game-of-life/behaviour/examples
    rspec/examples/stories/game-of-life/behaviour/stories
    rspec/examples/stories/game-of-life/life
    rspec/examples/stories/steps
    rspec/failing_examples
    rspec/lib
    rspec/lib/autotest
    rspec/lib/spec
    rspec/lib/spec/example
    rspec/lib/spec/expectations
    rspec/lib/spec/expectations/differs
    rspec/lib/spec/expectations/extensions
    rspec/lib/spec/extensions
    rspec/lib/spec/interop
    rspec/lib/spec/interop/test
    rspec/lib/spec/interop/test/unit
    rspec/lib/spec/interop/test/unit/ui
    rspec/lib/spec/interop/test/unit/ui/console
    rspec/lib/spec/matchers
    rspec/lib/spec/mocks
    rspec/lib/spec/mocks/extensions
    rspec/lib/spec/rake
    rspec/lib/spec/runner
    rspec/lib/spec/runner/formatter
    rspec/lib/spec/runner/formatter/story
    rspec/lib/spec/story
    rspec/lib/spec/story/extensions
    rspec/lib/spec/story/runner
    rspec/plugins
    rspec/plugins/mock_frameworks
    rspec/pre_commit
    rspec/pre_commit/lib
    rspec/pre_commit/lib/pre_commit
    rspec/pre_commit/spec
    rspec/pre_commit/spec/pre_commit
    rspec/rake_tasks
    rspec/spec
    rspec/spec/autotest
    rspec/spec/spec
    rspec/spec/spec/example
    rspec/spec/spec/expectations
    rspec/spec/spec/expectations/differs
    rspec/spec/spec/expectations/extensions
    rspec/spec/spec/extensions
    rspec/spec/spec/interop
    rspec/spec/spec/interop/test
    rspec/spec/spec/interop/test/unit
    rspec/spec/spec/interop/test/unit/resources
    rspec/spec/spec/matchers
    rspec/spec/spec/mocks
    rspec/spec/spec/package
    rspec/spec/spec/runner
    rspec/spec/spec/runner/formatter
    rspec/spec/spec/runner/formatter/story
    rspec/spec/spec/runner/resources
    rspec/spec/spec/runner/spec_parser
    rspec/spec/spec/story
    rspec/spec/spec/story/extensions
    rspec/spec/spec/story/runner
    rspec/stories
    rspec/stories/example_groups
    rspec/stories/interop
    rspec/stories/pending_stories
    rspec/stories/resources
    rspec/stories/resources/helpers
    rspec/stories/resources/matchers
    rspec/stories/resources/spec
    rspec/stories/resources/steps
    rspec/stories/resources/stories
    rspec/stories/resources/test
    rspec/story_server
    rspec/story_server/prototype
    rspec/story_server/prototype/javascripts
    rspec/story_server/prototype/lib
    rspec/story_server/prototype/stylesheets
    rspec_on_rails
    rspec_on_rails/generators
    rspec_on_rails/generators/helpers
    rspec_on_rails/generators/rspec
    rspec_on_rails/generators/rspec/templates
    rspec_on_rails/generators/rspec/templates/script
    rspec_on_rails/generators/rspec_controller
    rspec_on_rails/generators/rspec_controller/templates
    rspec_on_rails/generators/rspec_model
    rspec_on_rails/generators/rspec_model/templates
    rspec_on_rails/generators/rspec_scaffold
    rspec_on_rails/generators/rspec_scaffold/templates
    rspec_on_rails/lib
    rspec_on_rails/lib/autotest
    rspec_on_rails/lib/spec
    rspec_on_rails/lib/spec/rails
    rspec_on_rails/lib/spec/rails/example
    rspec_on_rails/lib/spec/rails/extensions
    rspec_on_rails/lib/spec/rails/extensions/action_controller
    rspec_on_rails/lib/spec/rails/extensions/action_view
    rspec_on_rails/lib/spec/rails/extensions/active_record
    rspec_on_rails/lib/spec/rails/extensions/spec
    rspec_on_rails/lib/spec/rails/extensions/spec/example
    rspec_on_rails/lib/spec/rails/extensions/spec/matchers
    rspec_on_rails/lib/spec/rails/matchers
    rspec_on_rails/spec
    rspec_on_rails/spec/rails
    rspec_on_rails/spec/rails/autotest
    rspec_on_rails/spec/rails/example
    rspec_on_rails/spec/rails/extensions
    rspec_on_rails/spec/rails/matchers
    rspec_on_rails/spec/rails/mocks
    rspec_on_rails/spec_resources
    rspec_on_rails/spec_resources/controllers
    rspec_on_rails/spec_resources/helpers
    rspec_on_rails/spec_resources/views
    rspec_on_rails/spec_resources/views/controller_spec
    rspec_on_rails/spec_resources/views/render_spec
    rspec_on_rails/spec_resources/views/rjs_spec
    rspec_on_rails/spec_resources/views/tag_spec
    rspec_on_rails/spec_resources/views/view_spec
    rspec_on_rails/spec_resources/views/view_spec/foo
    rspec_on_rails/stories
    rspec_on_rails/stories/steps
    rspec_on_rails/tasks
)
end
