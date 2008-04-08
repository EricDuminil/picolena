desc 'Ferret index maintenance tasks'
namespace :index do  
  desc 'Clear indexes'
  task :clear => :environment do
    require 'fileutils'
    Dir.glob(File.join(IndexSavePath,'/**/*')).each{|f| FileUtils.rm(f) if File.file?(f)}
  end
  
  desc 'Create index'
  task :create => :environment do
    require 'ff'
    create_index(IndexedDirectories.keys)
  end

  desc 'Update index'
  task :update do
    puts "Implement me!"
  end
  
  # Search index with query "some query" :
  # rake index:search query="some query"
  desc 'Search index'
  task :search => :environment do
    Finder.new(ENV["query"]).matching_documents.entries.each{|doc| puts doc.to_s}
  end
end
