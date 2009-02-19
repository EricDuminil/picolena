# Finder is the class that is in charge to ensure that an index is instantiated and
# that the raw query is converted into a Ferret::Query.
# It then launches a search and returns found documents with corresponding matching scores.
class Finder
  attr_reader :query

  # No need to instantiate a new index for every search, so it gets cached.
  def index
    @@index ||= Indexer.index 
  end

  # Instantiates a new Finder
  # extracts a Ferret::Query from plain text raw query
  # ensures that an Index has been instantiated
  # reloads the index if needed
  # prepares matching_documents pagination
  # and ensures that the index contains at least one document.
  def initialize(raw_query,sort_by='relevance', page=1,results_per_page=Picolena::ResultsPerPage)
    @query = Query.extract_from(raw_query)
    @raw_query= raw_query
    Indexer.ensure_index_existence
    reload_index! if should_be_reloaded?
    @per_page=results_per_page
    @offset=(page.to_i-1)*results_per_page
    @sort_by=sort_by
    index_should_have_documents
  end

  # Launches the search and writes correspondings
  #  @matching_documents
  #  @total_hits
  #  @time_needed
  #
  # If a document is found in the index but not on the filesystem, it doesn't appear on
  # the @matching_documents list.
  def execute!
    @matching_documents=[]
    start=Time.now
      @total_hits = index.search_each(query, :limit => @per_page, :offset=>@offset, :sort => (sort_by_date if @sort_by=='date')){|index_id, score|
        found_doc=Document[index[index_id][:complete_path]]
        found_doc.matching_content=index.highlight(query, index_id,
                                                   :field => :cache_content, :excerpt_length => 80,
                                                   :pre_tag => "<<", :post_tag => ">>"
        )
        found_doc.score=score
        @matching_documents<<found_doc if found_doc.valid?# && File.exists?(found_doc.complete_path)
      }
      @executed=true
    @time_needed=Time.now-start
  end

  # Returns true if it has been executed.
  def executed?
    @executed
  end

  # To ensure that
  #  matching_documents
  #  total_hits
  #  time_needed
  # methods are called only after the index has been searched.
  [:matching_documents, :total_hits, :time_needed].each{|attribute_name|
    define_method(attribute_name){
      execute! unless executed?
      instance_variable_get("@#{attribute_name}")
    }
  }

  private
  # Closes Index and clears the cache.
  # This is used when the index has been modified by an external process
  # and needs to get reloaded.
  # Processes sharing the same index can force each other to reload by touching
  # the "reload" file in Picolena::MetaIndexPath.
  def reload_index!
    Indexer.close
    @@index = nil
    @@last_reload = Time.now
  end

  # Returns true if reload file has been touched since last reload.
  def should_be_reloaded?
    Indexer.reload_file_mtime > last_reload
  end

  # Returns the last time the index was reloaded.
  # Returns Time.at(0) if undefined.
  def last_reload
    @@last_reload ||= Time.at(0)
  end
 
  # Returns a SortField that sorts documents by reversed modified time.
  def sort_by_date
    Ferret::Search::SortField.new(:modified, :type => :byte, :reverse => true)
  end

  # Raises if index does not contain any document.
  def index_should_have_documents
    raise IndexError, "no document found" unless index.size > 0
  end
end
