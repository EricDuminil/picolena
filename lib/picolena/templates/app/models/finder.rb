class Finder
  attr_reader :query

  def index
    @@index ||= Indexer.index
  end

  def initialize(raw_query,sort_by='relevance', page=1,results_per_page=Picolena::ResultsPerPage)
    @query = Query.extract_from(raw_query)
    @raw_query= raw_query
    Indexer.ensure_index_existence
    @per_page=results_per_page
    @offset=(page.to_i-1)*results_per_page
    @sort_by=sort_by
    index_should_have_documents
  end

  def execute!
    @matching_documents=[]
    start=Time.now
      @total_hits = index.search_each(query, :limit => @per_page, :offset=>@offset, :sort => (sort_by_date if @sort_by=='date')){|index_id, score|
        begin
          found_doc=Document.new(index[index_id][:complete_path])
          found_doc.matching_content=index.highlight(query, index_id,
                                                     :field => :content, :excerpt_length => 80,
                                                     :pre_tag => "<<", :post_tag => ">>"
          )
          found_doc.score=score
          @matching_documents<<found_doc
        rescue Errno::ENOENT
          #"File has been moved/deleted!"
        end
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

  def self.reload!
    @@index = nil
  end

  private
  
  def sort_by_date
    Ferret::Search::SortField.new(:modified, :type => :byte, :reverse => true)
  end

  def index_should_have_documents
    raise IndexError, "no document found" unless index.size > 0
  end
end
