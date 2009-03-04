desc 'Ferret index maintenance tasks'
namespace :index do
  desc 'Clear index for the given environment'
  task :clear => :environment do
    Indexer.clear!
  end

  #TODO: db:migrate before index:create
  desc 'Create index'
  task :create => :environment do
    Indexer.index_every_directory(remove_first=true)
  end

  desc 'Update index'
  task :update => :environment do
    Indexer.index_every_directory
  end
  
  desc 'Remove unneeded files from index'
  task :prune => :environment do
    Indexer.prune_index
  end

  desc 'Returns the number of indexed documents'
  task :size => :environment do
    puts "#{Indexer.size} documents are currently indexed in #{Picolena::IndexSavePath}"
  end

  desc 'Returns the last time the index was created/update'
  task :last_update => :environment do
    puts Indexer.last_update
  end

  # Search index with query "some query" :
  # rake index:search query="some query"
  desc 'Search index'
  task :search => :environment do
    puts Finder.new(ENV["query"]).matching_documents.entries.collect{|doc| doc.inspect}.join("\n"<<"#"*80<<"\n")
  end
end
