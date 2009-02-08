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

    @directories_to_index=if options[:spec_only] then
       "/whatever : /whatever"
    else
      ARGV.collect{|relative_path|
        abs_dir=Pathname.new(relative_path).realpath.to_s
        "\"#{abs_dir}\" : \"#{abs_dir}\""
      }.join("\n  ")      
    end

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
      m.template '../config/environment.rb', 'config/environment.rb', :assigns => {:version => Picolena::VERSION::STRING}
      m.file '../config/white_list_ip.yml', 'config/custom/white_list_ip.yml'
      m.file '../config/basic.rb', 'config/custom/picolena.rb'
      m.template '../config/indexed_directories.yml', 'config/custom/indexed_directories.yml', :assigns => {:directories_to_index => @directories_to_index}
      m.template '../config/title_and_names_and_links.yml', 'config/custom/title_and_names_and_links.yml', :assigns => {:version => Picolena::VERSION::STRING}
      m.file '../config/icons_and_filetypes.yml', 'config/custom/icons_and_filetypes.yml'
      m.file '../config/indexing_performance.yml', 'config/custom/indexing_performance.yml'

      # README, License & Rakefile
      m.file 'MIT-LICENSE', 'LICENSE'
      m.file '../../../README.txt', 'README'
      m.file '../../../README.txt', 'doc/README_FOR_APP'
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
      m.clean if false
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
    config/custom
    doc
    lang/ui
    lib
    lib/plain_text_extractors
    lib/tasks
    log
    public
    public/help
    public/images
    public/images/icons
    public/images/flags
    public/images/thumbnails
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
    spec/test_dirs/indexed/archives
    spec/test_dirs/indexed/basic
    spec/test_dirs/indexed/different_encodings
    spec/test_dirs/indexed/just_one_doc
    spec/test_dirs/indexed/lang
    spec/test_dirs/indexed/literature
    spec/test_dirs/indexed/media
    spec/test_dirs/indexed/others
    spec/test_dirs/indexed/others/nested
    spec/test_dirs/indexed/yet_another_dir
    spec/test_dirs/not_indexed
    spec/views
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
)
end
