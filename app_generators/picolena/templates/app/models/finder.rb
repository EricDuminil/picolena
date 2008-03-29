require 'ff'

class Finder
  attr_reader :index, :query
  
  def initialize(raw_query,page=1,results_per_page=ResultsPerPage)
    query_parser = Ferret::QueryParser.new(:fields => [:content, :file, :basename, :filetype], :or_default => false, :analyzer=>Analyzer)
    @query = query_parser.parse(convert_to_english(raw_query))
    @raw_query= raw_query
    Finder.ensure_that_index_exists_on_disk
    @index = Ferret::Index::Index.new(:path => IndexSavePath, :analyzer=>Analyzer)
    @per_page=results_per_page
    @offset=(page.to_i-1)*results_per_page
    validate_that_index_has_documents
  end
  
  def execute!
    @matching_documents=[]
    start=Time.now
    begin
      top_docs=index.search(query, :limit => @per_page, :offset=>@offset)
      top_docs.hits.each{|hit|
        ferret_doc,score=hit.doc,hit.score
        begin
          found_doc=Document.new(index[ferret_doc][:complete_path])
          found_doc.matching_content=index.highlight(query, ferret_doc,
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
    ensure
      index.close
    end
  end
  
  def executed?
    @executed
  end
  
  [:matching_documents, :total_hits, :time_needed].each{|attribute_name|
    define_method(attribute_name){
      execute! unless executed?
      instance_variable_get("@#{attribute_name}")
    }
  }
   
   def self.has_index?
     index_filename and File.exists?(index_filename)
   end
   
   def has_documents?
     index.size>0
   end
   
   def self.up_to_date?
     IndexedDirectories.keys.all?{|dir| File.mtime(index_filename) > File.mtime(dir)}
   end
   
   private
   
   def convert_to_english(str)
     to_en={
       /\b#{:AND.l}\b/=>'AND',
       /\b#{:OR.l}\b/=>'OR',
       /\b#{:NOT.l}\b/=>'NOT',
       /(#{:filetype.l}):/=>'filetype:',
       /#{:content.l}:/ => 'content:',
       /\b#{:LIKE.l}\s+(\S+)/=>'\1~'
     }
     to_en.inject(str){|mem,non_english_to_english_keyword|
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
     create_index(IndexedDirectories.keys)
   end
   
   def self.delete_index
     FileUtils.rm(Dir.glob(File.join(IndexSavePath,'*.cfs'))) if has_index?
   end
   
   def validate_that_index_has_documents
     raise IndexError, "no document found" unless has_documents?
   end 
end