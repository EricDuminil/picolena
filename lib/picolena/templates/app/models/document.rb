# Document class retrieves information from filesystem and the index for any given document.
# TODO: Update doc to reflect changes in sphinx branch
# TODO: Clean up unneeded methods
class Document < ActiveRecord::Base
  ActiveRecord::Base.extend(ActiveSupport::Memoizable)

  attr_accessor :score, :matching_content, :extract_error

  validate             :must_be_an_existing_file
  validate             :must_be_in_an_indexed_directory
  validates_length_of  :cache_content, :in => 1 .. Picolena::IndexingConfiguration[:max_content_length], :allow_blank => true

  define_index do
    indexes cache_content, :as => :content
    indexes complete_path, :as => :path
    indexes alias_path, filename, basename, filetype
    indexes language
    indexes cache_mtime, :as => :modified
  end

  class << self
    def extract_content_from(path)
      new(:complete_path => File.expand_path(path)).content
    end

    def find_or_create_with_content(path)
      complete_path=File.expand_path(path)
      find_or_create_by_complete_path(complete_path) do |doc|
        doc.extract_fs_info!
        doc.extract_doc_info!(:truncate)
      end
    end
    alias_method :[], :find_or_create_with_content
  end

  def extract_fs_info!
    # Returns an id for this document.
    # This id will be used in Controllers in order to get tiny urls.
    # Since it's a base26 hash of the absolute filename, it can only be "probably unique".
    # For huge amount of indexed documents, it would be wise to increase HashLength in config/custom/picolena.rb
    self.probably_unique_id = complete_path.base26_hash
    self.filename           = File.basename(complete_path)
    self.filetype           = File.extname(complete_path)
    # Returns filename without extension
    #   "buildings.odt" => "buildings"
    self.basename           = File.basename(complete_path, filetype)
    get_alias_path!
  end

  def extract_doc_info!(truncate=false)
    self.cache_content, self.language = extract_content_and_language(truncate)
    extract_thumbnail
    self.cache_mtime = mtime
  end

  
  # Delegating properties to File::method_name(complete_path)
  [:dirname, :file?, :plain_text?, :size, :ext_as_sym].each{|method_name|
    define_method(method_name){File.send(method_name,complete_path)}
  }
  alias_attribute :to_s, :complete_path


  # Returns complete path as well as matching score and language if available.
  #  ../spec/test_dirs/indexed/just_one_doc/for_test.txt (56.3%) (language:en)
  # Used for example by
  #  rake index:search query="some query"
  def inspect
    [self,("(#{pretty_score})" if @score),("(language:#{language})" if language)].compact.join(" ")
  end



  # Returns true iff some PlainTextExtractor has been defined to convert it to plain text.
  #  Document.new(:complete_path => "presentation.pdf").supported? => true
  #  Document.new(:complete_path => "presentation.some_weird_extension").supported? => false
  def supported?
    if extractor.is_an?(EmptyExtractor) then
      self.extract_error="no convertor for #{filetype}"
    else
      self.extract_error="binary file" if ext_as_sym==:no_extension and !plain_text?
    end
    !extract_error
  end

  # Returns a PlainTextExtractor, if available.
  # The extractor is found according to Document#filetype, and then duplicated
  # in order to avoid racing conditions between 2 different documents with 
  # the same filetype, and hence the same PlainTextExtractor
  def extractor
    base_extractor=PlainTextExtractor.find_by_extension(ext_as_sym)
    if base_extractor then
      returning base_extractor.dup do |xtr|
        xtr.source = complete_path
      end
    else
      EmptyExtractor.instance
    end
  end
  memoize :extractor

  delegate      :extract_content, :extract_content_and_language, :extract_thumbnail, :mime,  :to => :extractor
  alias_method  :content, :extract_content

  # Returns cached content with matching terms between '<<' '>>'.
  def highlighted_cache(raw_query)
    excerpts=Indexer.index.highlight(Query.extract_from(raw_query), doc_id,
                            :field => :cache_content, :excerpt_length => :all,
                            :pre_tag => "<<", :post_tag => ">>"
             )
    excerpts.is_an?(Array) ? excerpts.first : ""
  end

  # Returns the last modification date before the document got indexed.
  # Useful to know how old a document is, and to which version the cache corresponds.
  #   >> doc.pretty_cache_mdate
  #   => "2008-05-09"
  def pretty_cache_mdate
    cache_mtime.strftime("%Y-%m-%d")
  end
  
  # Returns the last modification time before the document got indexed.
  #   >> doc.pretty_cache_mtime
  #   => "2008-05-09 09:39:51"
  # TODO: Remove pretty_mtime if not used in views
  def pretty_cache_mtime
    cache_mtime.strftime("%Y-%m-%d %H:%M:%S")
  end

  # Returns the Document modification time
  # mtime > cache_mtime means that the document has been modified since the last time
  # content has been extracted
  def mtime
    File.mtime(complete_path)
  end

  # Returns matching score as a percentage, e.g. 56.3%
  def pretty_score
    "%3.1f%" % (@score*100)
  end

  
  # Returns thumbnail if available, mime icon otherwise
  def icon_path
    if File.exists?(thumbnail_path) then
      thumbnail_path(:public_dir)
    else
      icon_symbol=Picolena::FiletypeToIconSymbol[ext_as_sym]
      "icons/#{icon_symbol}.png" if icon_symbol
    end
  end

  # Did at least one letter got extracted from the document?
  # This boolean is used in views to know if a link should be
  # displayed to show the content
  def has_content?
    cache_content =~ /\w/
  end

  # End users should not always know where documents are stored internally.
  # An alias path can be specified in config/indexed_directories.yml
  #
  # For example, with:
  #   "/media/wiki_dump/" : "http://www.mycompany.com/wiki/"
  #
  # The documents
  #   "/media/wiki_dump/organigram.odp"
  # will be displayed as being:
  #   "http://www.mycompany.com/wiki/organigram.odp"
  def get_alias_path!
    alias_dir=Picolena::IndexedDirectories[indexed_directory]
    self[:alias_path]=dirname.sub(indexed_directory,alias_dir) if indexed_directory
  end

  def has_been_modified?
    mtime > cache_mtime
  end
  
  private
 
  def thumbnail_path(public_dir=false)
    File.thumbnail_path(complete_path,public_dir)
  end
  
  # FIXME: Is there a way to easily retrieve doc_id for a given document?
  # Better yet, fix Index#highlight to accept :probably_unique_id and stop using :doc_id.
  def doc_id
    Indexer.index.search(Ferret::Search::TermQuery.new(:probably_unique_id,probably_unique_id)).hits.first.doc
  end

  # Returns the IndexedDirectory in which the Document is included.
  # Returns nil if no corresponding dir is found.
  def indexed_directory
    Picolena::IndexedDirectories.keys.find{|indexed_dir|
      dirname.starts_with?(indexed_dir)
    }
  end
  memoize :indexed_directory
  
  # NOTE: This validation is basically useless: it comes too late
  # File.mtime(complete_path) will raise before
  def must_be_an_existing_file
    errors.add(:complete_path, "is not an existing file") unless file?
  end

  # checks if @complete_path is included in an indexed_directory.
  # It prevents end user to get information about non-indexed sensitive files.
  # NOTE: Should it raise, or just add an error?
  def must_be_in_an_indexed_directory
    #raise ArgumentError, "required document is not in indexed directory" unless indexed_directory
    errors.add(:complete_path, "is not included in any indexed_directory") unless indexed_directory
  end
end
