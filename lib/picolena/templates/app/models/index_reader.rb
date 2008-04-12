class IndexReader < Ferret::Index::Index
  def initialize(params={})
    # TODO: Remove those debug lines!
    # puts "##################################################################Creating Reader!!!!!"
    # Add needed parameters
    params.merge!(:path => IndexSavePath, :analyzer => Analyzer)
    # Creates the IndexReader
    super(params)
  end
  
  # Returns the number of times a file is present in the index.
  # index_reader.doc_freq(field, term) → integer
  # Return the number of documents in which the term term appears in the field field. 
  def occurences_number(complete_path)
    # complete_path_query = Ferret::Search::TermQuery.new(:complete_path, complete_path)
    search_by_complete_path(complete_path).total_hits
  end
  
  def search_by_complete_path(complete_path)
    search('complete_path:"'<<complete_path<<'"')  
  end
  
  def delete_by_complete_path(complete_path)
    search_by_complete_path(complete_path).hits.each{|hit|
      delete(hit.doc)
    }
    close
  end
  
  
  # Validation methods.
  
  def should_have_documents
     raise IndexError, "no document found" unless has_documents?
  end
 
  # Returns true if there's at least one document indexed.
  def has_documents?
   size>0
  end
 
 class<<self

   def ensure_existence
     Indexer.index_every_directory(update=false) unless exists? or RAILS_ENV=="production"
   end
 
  def exists?
     filename and File.exists?(filename)
  end
 
  def filename
    Dir.glob(File.join(IndexSavePath,'*.cfs')).first
  end
  end
end