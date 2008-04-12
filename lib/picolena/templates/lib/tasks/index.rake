desc 'Ferret index maintenance tasks'
namespace :index do  
  desc 'Clear indexes'
  task :clear => :environment do
    Dir.glob(File.join(IndexesSavePath,'/**/*')).each{|f| FileUtils.rm(f) if File.file?(f)}
  end
  
  desc 'Create index'
  task :create => :environment do
    Indexer.index_every_directory(update=false)
  end

  desc 'Update index'
  task :update => :environment do
    Indexer.index_every_directory(update=true)
  end
  
  # Search index with query "some query" :
  # rake index:search query="some query"
  desc 'Search index'
  task :search => :environment do
    Finder.new(ENV["query"]).matching_documents.entries.each{|doc| puts doc.to_s}
  end
end
