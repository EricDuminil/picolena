desc 'Ferret index maintenance tasks'
namespace :index do  
  desc 'Clear indexes'
  task :clear => :environment do
    require 'fileutils'
    Dir.glob('tmp/ferret_indexes/**/*').each{|f| FileUtils.rm(f) if File.file?(f)}
  end
  
  desc 'Create configuration files from template'
  task :prepare_config do
    require 'fileutils'
    %w{config/indexed_directories.yml config/white_list_ip.yml}.each{|yaml_config_file|
      FileUtils.cp(yaml_config_file+'.template', yaml_config_file) unless File.readable?(yaml_config_file)
    }
  end  

  desc 'Create index'
  task :create => [:prepare_config, :environment] do
    require 'ff'
    create_index(IndexedDirectories.keys)
  end

  desc 'Update index'
  task :update => :environment do
    puts "Implement me!"
  end
  
  # Search index with query "some query" :
  # rake index:search query="some query"
  desc 'Search index'
  task :search => :environment do
    Finder.new(ENV["query"]).matching_documents.entries.each{|doc| puts doc.to_s}
  end
end