class IndexReader < Ferret::Index::Index
  def initialize(params={})
    # Add needed parameters
    params.merge!(:path => IndexSavePath, :analyzer => Analyzer)
    # Creates the IndexReader
    super(params)
  end
  
  # Returns the number of times a file is present in the index.
  def occurences_number(complete_path)
    # complete_path_query = Ferret::Search::TermQuery.new(:complete_path, complete_path)
    search_by_complete_path(complete_path).total_hits
  end
  
  def document(complete_path)
    search_by_complete_path(path)
  end
  
  def cached_mtime(complete_path)
    
  end

  def search_by_complete_path(complete_path)
    search('complete_path:"'<<complete_path<<'"')  
  end
  
  def delete_by_complete_path(complete_path)
    search_by_complete_path(complete_path).hits.each{|hit|
      delete(hit.doc)
    }
  end
end