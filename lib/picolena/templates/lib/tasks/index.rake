desc 'Ferret index maintenance tasks'
namespace :index do
  desc 'Clear indexes'
  task :clear => :environment do
    Indexer.clear! :all
  end

  desc 'Create index'
  task :create => :environment do
    Indexer.index_every_directory(remove_first=true)
  end

  desc 'Update index'
  task :update => :environment do
    Indexer.index_every_directory
  end

  desc 'Returns the number of indexed documents'
  task :size => :environment do
    puts "#{Indexer.doc_count} documents are currently indexed in #{Picolena::IndexSavePath}"
  end

  # Search index with query "some query" :
  # rake index:search query="some query"
  desc 'Search index'
  task :search => :environment do
    Finder.new(ENV["query"]).matching_documents.entries.each{|doc| puts doc.to_s}
  end
end
