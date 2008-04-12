#require 'ff'

class Finder
  #FIXME: Should not use all those class methods to access index.
  
  attr_reader :query
  
  def self.index
    # caching index @@index ||=  
    # causes ferret-0.11.6/lib/ferret/index.rb:768: [BUG] Segmentation fault
    Ferret::Index::Index.new(:path => IndexSavePath, :analyzer=>Analyzer)  
  end
  
  def initialize(raw_query,page=1,results_per_page=ResultsPerPage)
    query_parser = Ferret::QueryParser.new(:fields => [:content, :file, :basename, :filetype, :date], :or_default => false, :analyzer=>Analyzer)
    @query = query_parser.parse(convert_to_english(raw_query))
    @raw_query= raw_query
    Finder.ensure_that_index_exists_on_disk
    @per_page=results_per_page
    @offset=(page.to_i-1)*results_per_page
    validate_that_index_has_documents
  end
  
  def execute!
    @matching_documents=[]
    start=Time.now
    begin
      top_docs=Finder.index.search(query, :limit => @per_page, :offset=>@offset)
      top_docs.hits.each{|hit|
        index_id,score=hit.doc,hit.score
        begin
          found_doc=Document.new(Finder.index[index_id][:complete_path])
          found_doc.matching_content=Finder.index.highlight(query, index_id,
                                                     :field => :content, :excerpt_length => 80,
                                                     :pre_tag => "<<", :post_tag => ">>"
          ) unless @raw_query=~/^\*+\.\w*$/
          found_doc.score=score
          found_doc.index_id=index_id
          @matching_documents<<found_doc
        rescue Errno::ENOENT
          #"File has been moved/deleted!"
        end
      }
      @executed=true
      @time_needed=Time.now-start
      @total_hits=top_docs.total_hits
    ensure
      #index.close
    end
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
   
   # Returns true if index is existing.
   def self.has_index?
     index_filename and File.exists?(index_filename)
   end
   
   # Returns true if there's at least one document indexed.
   def has_documents?
     Finder.index.size>0
   end

   # Returns matching document for any given query, if only
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
   
   private
   
   # Convert query keywords to english so they can be parsed by Ferret.
   def convert_to_english(query)
     to_en={
       /\b#{:AND.l}\b/=>'AND',
       /\b#{:OR.l}\b/=>'OR',
       /\b#{:NOT.l}\b/=>'NOT',
       /(#{:filetype.l}):/=>'filetype:',
       /#{:content.l}:/ => 'content:',
       /#{:date.l}:/ => 'date:',
       /\b#{:LIKE.l}\s+(\S+)/=>'\1~'
     }
     to_en.inject(query){|mem,non_english_to_english_keyword|
       mem.gsub(*non_english_to_english_keyword)
     }
   end
   
   def self.index_filename
     Dir.glob(File.join(IndexSavePath,'*.cfs')).first
   end

   def self.ensure_that_index_exists_on_disk
     force_index_creation unless has_index? or RAILS_ENV=="production"
   end
   
   def self.force_index_creation
     #create_index(IndexedDirectories.keys)
     Indexer.reset!
     Indexer.index_every_directory
   end
   
   def self.delete_index
     FileUtils.rm(Dir.glob(File.join(IndexSavePath,'*.cfs'))) if has_index?
   end
   
   def validate_that_index_has_documents
     raise IndexError, "no document found" unless has_documents?
   end 
end
