class Finder
  attr_reader :query

  def index
    @@index ||= Indexer.index
  end

  def initialize(raw_query,page=1,results_per_page=Picolena::ResultsPerPage)
    @query = Query.extract_from(raw_query)
    @raw_query= raw_query
    Indexer.ensure_index_existence
    @per_page=results_per_page
    @offset=(page.to_i-1)*results_per_page
    index_should_have_documents
  end

  def execute!
    @matching_documents=[]
    start=Time.now
    top_docs=index.search(query, :limit => @per_page, :offset=>@offset)
    top_docs.hits.each{|hit|
      index_id,score=hit.doc,hit.score
      begin
        found_doc=Document.new(index[index_id][:complete_path])
        found_doc.matching_content=index.highlight(query, index_id,
                                                   :field => :content, :excerpt_length => 80,
                                                   :pre_tag => "<<", :post_tag => ">>"
        ) unless @raw_query=~/^\*+\.\w*$/
        found_doc.score=score
        @matching_documents<<found_doc
      rescue Errno::ENOENT
        #"File has been moved/deleted!"
      end
      }
      @executed=true
      @time_needed=Time.now-start
      @total_hits=top_docs.total_hits
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

   # Returns matching document for any given query only if
   # exactly one document is found.
   # Raises otherwise.
  def matching_document
    case matching_documents.size
    when 0
      raise IndexError, "No document found"
    when 1
      matching_documents.first
    else
      raise IndexError, "More than one document found"
    end
  end

  def self.reload!
    @@index = nil
  end

  private

  def index_should_have_documents
    raise IndexError, "no document found" unless index.size > 0
  end
end