require 'tempfile'
require 'fileutils'
require 'pathname'

class PicolenaGenerator < RubiGen::Base
  
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
      BASEDIRS.each { |path|
        # Ensure appropriate folder(s) exists
        m.directory path
        # Copy every file included in BASEDIRS
        m.folder path, path
      }

      # Copy every Rails script with exec persmissions.
      m.directory 'script'
      m.directory 'script/performance'
      m.directory 'script/process'
      %w( about console destroy generate performance/benchmarker performance/profiler performance/request process/reaper process/spawner process/inspector runner server plugin ).each do |file|
        m.file "script/#{file}", "script/#{file}", script_options
      end
      
      # Picolena configuration files
      m.file '../config/white_list_ip.yml', 'config/white_list_ip.yml'
      m.template '../config/indexed_directories.yml', 'config/indexed_directories.yml', :assigns => {:directories_to_index => @directories_to_index}

      # README, License & Rakefile
      m.file 'MIT-LICENSE', 'LICENSE'
      m.file '../../../README.txt', 'README'
      m.file 'Rakefile', 'Rakefile'
     
      unless options[:spec_only] or options[:no_index]
        # Indexing documents for development environment
        m.rake 'index:create' 
        # Mirroring Ferret development index instead of indexing documents again for production.
        m.mirror 'tmp/ferret_indexes/development', 'tmp/ferret_indexes/production' unless options[:spec_only]
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
    app
    app/controllers
    app/helpers
    app/models
    app/views
    app/views/documents
    app/views/layouts
    config
    config/environments
    config/initializers
    doc
    lang
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
    tmp
    tmp/cache
    tmp/ferret_indexes
    tmp/pids
    tmp/sessions
    tmp/sockets
    vendor
    vendor/plugins
    vendor/plugins/globalite
    vendor/plugins/globalite/data
    vendor/plugins/globalite/lang
    vendor/plugins/globalite/lang/rails
    vendor/plugins/globalite/lib
    vendor/plugins/globalite/lib/globalite
    vendor/plugins/globalite/lib/rails
    vendor/plugins/globalite/rdoc
    vendor/plugins/globalite/rdoc/classes
    vendor/plugins/globalite/rdoc/classes/ActionView
    vendor/plugins/globalite/rdoc/classes/ActionView/Helpers
    vendor/plugins/globalite/rdoc/classes/ActiveRecord
    vendor/plugins/globalite/rdoc/classes/Globalite
    vendor/plugins/globalite/rdoc/files
    vendor/plugins/globalite/rdoc/files/lib
    vendor/plugins/globalite/rdoc/files/lib/globalite
    vendor/plugins/globalite/rdoc/files/lib/rails
    vendor/plugins/globalite/spec
    vendor/plugins/globalite/spec/helpers
    vendor/plugins/globalite/spec/lang
    vendor/plugins/globalite/spec/lang/rails
    vendor/plugins/globalite/spec/lang/ui
    vendor/plugins/globalite/tasks
    vendor/plugins/haml
    vendor/plugins/rspec
    vendor/plugins/rspec/autotest
    vendor/plugins/rspec/bin
    vendor/plugins/rspec/examples
    vendor/plugins/rspec/examples/pure
    vendor/plugins/rspec/examples/stories
    vendor/plugins/rspec/examples/stories/game-of-life
    vendor/plugins/rspec/examples/stories/game-of-life/behaviour
    vendor/plugins/rspec/examples/stories/game-of-life/behaviour/examples
    vendor/plugins/rspec/examples/stories/game-of-life/behaviour/stories
    vendor/plugins/rspec/examples/stories/game-of-life/life
    vendor/plugins/rspec/examples/stories/steps
    vendor/plugins/rspec/failing_examples
    vendor/plugins/rspec/lib
    vendor/plugins/rspec/lib/autotest
    vendor/plugins/rspec/lib/spec
    vendor/plugins/rspec/lib/spec/example
    vendor/plugins/rspec/lib/spec/expectations
    vendor/plugins/rspec/lib/spec/expectations/differs
    vendor/plugins/rspec/lib/spec/expectations/extensions
    vendor/plugins/rspec/lib/spec/extensions
    vendor/plugins/rspec/lib/spec/interop
    vendor/plugins/rspec/lib/spec/interop/test
    vendor/plugins/rspec/lib/spec/interop/test/unit
    vendor/plugins/rspec/lib/spec/interop/test/unit/ui
    vendor/plugins/rspec/lib/spec/interop/test/unit/ui/console
    vendor/plugins/rspec/lib/spec/matchers
    vendor/plugins/rspec/lib/spec/mocks
    vendor/plugins/rspec/lib/spec/mocks/extensions
    vendor/plugins/rspec/lib/spec/rake
    vendor/plugins/rspec/lib/spec/runner
    vendor/plugins/rspec/lib/spec/runner/formatter
    vendor/plugins/rspec/lib/spec/runner/formatter/story
    vendor/plugins/rspec/lib/spec/story
    vendor/plugins/rspec/lib/spec/story/extensions
    vendor/plugins/rspec/lib/spec/story/runner
    vendor/plugins/rspec/plugins
    vendor/plugins/rspec/plugins/mock_frameworks
    vendor/plugins/rspec/pre_commit
    vendor/plugins/rspec/pre_commit/lib
    vendor/plugins/rspec/pre_commit/lib/pre_commit
    vendor/plugins/rspec/pre_commit/spec
    vendor/plugins/rspec/pre_commit/spec/pre_commit
    vendor/plugins/rspec/rake_tasks
    vendor/plugins/rspec/spec
    vendor/plugins/rspec/spec/autotest
    vendor/plugins/rspec/spec/spec
    vendor/plugins/rspec/spec/spec/example
    vendor/plugins/rspec/spec/spec/expectations
    vendor/plugins/rspec/spec/spec/expectations/differs
    vendor/plugins/rspec/spec/spec/expectations/extensions
    vendor/plugins/rspec/spec/spec/extensions
    vendor/plugins/rspec/spec/spec/interop
    vendor/plugins/rspec/spec/spec/interop/test
    vendor/plugins/rspec/spec/spec/interop/test/unit
    vendor/plugins/rspec/spec/spec/interop/test/unit/resources
    vendor/plugins/rspec/spec/spec/matchers
    vendor/plugins/rspec/spec/spec/mocks
    vendor/plugins/rspec/spec/spec/package
    vendor/plugins/rspec/spec/spec/runner
    vendor/plugins/rspec/spec/spec/runner/formatter
    vendor/plugins/rspec/spec/spec/runner/formatter/story
    vendor/plugins/rspec/spec/spec/runner/resources
    vendor/plugins/rspec/spec/spec/runner/spec_parser
    vendor/plugins/rspec/spec/spec/story
    vendor/plugins/rspec/spec/spec/story/extensions
    vendor/plugins/rspec/spec/spec/story/runner
    vendor/plugins/rspec/stories
    vendor/plugins/rspec/stories/example_groups
    vendor/plugins/rspec/stories/interop
    vendor/plugins/rspec/stories/pending_stories
    vendor/plugins/rspec/stories/resources
    vendor/plugins/rspec/stories/resources/helpers
    vendor/plugins/rspec/stories/resources/matchers
    vendor/plugins/rspec/stories/resources/spec
    vendor/plugins/rspec/stories/resources/steps
    vendor/plugins/rspec/stories/resources/stories
    vendor/plugins/rspec/stories/resources/test
    vendor/plugins/rspec/story_server
    vendor/plugins/rspec/story_server/prototype
    vendor/plugins/rspec/story_server/prototype/javascripts
    vendor/plugins/rspec/story_server/prototype/lib
    vendor/plugins/rspec/story_server/prototype/stylesheets
    vendor/plugins/rspec_on_rails
    vendor/plugins/rspec_on_rails/generators
    vendor/plugins/rspec_on_rails/generators/helpers
    vendor/plugins/rspec_on_rails/generators/rspec
    vendor/plugins/rspec_on_rails/generators/rspec/templates
    vendor/plugins/rspec_on_rails/generators/rspec/templates/script
    vendor/plugins/rspec_on_rails/generators/rspec_controller
    vendor/plugins/rspec_on_rails/generators/rspec_controller/templates
    vendor/plugins/rspec_on_rails/generators/rspec_model
    vendor/plugins/rspec_on_rails/generators/rspec_model/templates
    vendor/plugins/rspec_on_rails/generators/rspec_scaffold
    vendor/plugins/rspec_on_rails/generators/rspec_scaffold/templates
    vendor/plugins/rspec_on_rails/lib
    vendor/plugins/rspec_on_rails/lib/autotest
    vendor/plugins/rspec_on_rails/lib/spec
    vendor/plugins/rspec_on_rails/lib/spec/rails
    vendor/plugins/rspec_on_rails/lib/spec/rails/example
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions/action_controller
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions/action_view
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions/active_record
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions/spec
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions/spec/example
    vendor/plugins/rspec_on_rails/lib/spec/rails/extensions/spec/matchers
    vendor/plugins/rspec_on_rails/lib/spec/rails/matchers
    vendor/plugins/rspec_on_rails/spec
    vendor/plugins/rspec_on_rails/spec/rails
    vendor/plugins/rspec_on_rails/spec/rails/autotest
    vendor/plugins/rspec_on_rails/spec/rails/example
    vendor/plugins/rspec_on_rails/spec/rails/extensions
    vendor/plugins/rspec_on_rails/spec/rails/matchers
    vendor/plugins/rspec_on_rails/spec/rails/mocks
    vendor/plugins/rspec_on_rails/spec_resources
    vendor/plugins/rspec_on_rails/spec_resources/controllers
    vendor/plugins/rspec_on_rails/spec_resources/helpers
    vendor/plugins/rspec_on_rails/spec_resources/views
    vendor/plugins/rspec_on_rails/spec_resources/views/controller_spec
    vendor/plugins/rspec_on_rails/spec_resources/views/render_spec
    vendor/plugins/rspec_on_rails/spec_resources/views/rjs_spec
    vendor/plugins/rspec_on_rails/spec_resources/views/tag_spec
    vendor/plugins/rspec_on_rails/spec_resources/views/view_spec
    vendor/plugins/rspec_on_rails/spec_resources/views/view_spec/foo
    vendor/plugins/rspec_on_rails/stories
    vendor/plugins/rspec_on_rails/stories/steps
    vendor/plugins/rspec_on_rails/tasks
)
end
