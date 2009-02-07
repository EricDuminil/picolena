# Document class retrieves information from filesystem and the index for any given document.
class Document
  attr_reader :complete_path
  attr_accessor :score, :matching_content

  # Instantiates a new Document, and ensure that the given path exists and
  # is included in an indexed directory.
  # Raises otherwise.
  def initialize(path)
    # To ensure @complete_path is an absolute direction.
    @complete_path=File.expand_path(path)
    validate_existence_of_file
    validate_in_indexed_directory
  end

  # Delegating properties to File::method_name(complete_path)
  [:dirname, :basename, :extname, :ext_as_sym, :file?, :plain_text?, :size, :ext_as_sym].each{|method_name|
    define_method(method_name){File.send(method_name,complete_path)}
  }
  alias_method :filename, :basename
  alias_method :to_s, :complete_path


  # Returns complete path as well as matching score and language if available.
  #  ../spec/test_dirs/indexed/just_one_doc/for_test.txt (56.3%) (language:en)
  # Used for example by
  #  rake index:search query="some query"
  def inspect
    [self,("(#{pretty_score})" if @score),("(language:#{language})" if language)].compact.join(" ")
  end

  # Returns filename without extension
  #   "buildings.odt" => "buildings"
  def basename
    filename.chomp(extname)
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
  def alias_path
    original_dir=indexed_directory
    alias_dir=Picolena::IndexedDirectories[original_dir]
    dirname.sub(original_dir,alias_dir)
  end

  # Returns an id for this document.
  # This id will be used in Controllers in order to get tiny urls.
  # Since it's a base26 hash of the absolute filename, it can only be "probably unique".
  # For huge amount of indexed documents, it would be wise to increase HashLength in config/custom/picolena.rb
  def probably_unique_id
    @probably_unique_id||=complete_path.base26_hash
  end

  # Returns true iff some PlainTextExtractor has been defined to convert it to plain text.
  #  Document.new("presentation.pdf").supported? => true
  #  Document.new("presentation.some_weird_extension").supported? => false
  def supported?
    PlainTextExtractor.supported_extensions.include?(self.ext_as_sym) unless ext_as_sym==:no_extension and !plain_text?
  end

  def extractor
    PlainTextExtractor.find_by_extension(self.ext_as_sym) rescue nil
  end

  def mime
    extractor.mime_name rescue 'application/octet-stream'
  end

  # Retrieves content as it is *now*.
  def content
    PlainTextExtractor.extract_content_from(complete_path)
  end

  # Cache à la Google.
  # Returns content as it was at the time it was indexed.
  def cached
    from_index[:content]
  end
  
  # Returns cached content with matching terms between '<<' '>>'.
  def highlighted_cache(raw_query)
    excerpts=Indexer.index.highlight(Query.extract_from(raw_query), doc_id,
                            :field => :content, :excerpt_length => :all,
                            :pre_tag => "<<", :post_tag => ">>"
             )
    excerpts.is_an?(Array) ? excerpts.first : ""
  end

  # Returns the last modification date before the document got indexed.
  # Useful to know how old a document is, and to which version the cache corresponds.
  #   >> doc.pretty_date
  #   => "2008-05-09"
  def pretty_date
    from_index[:modified].sub(/(\d{4})(\d{2})(\d{2})\d{6}/,'\1-\2-\3')
  end
  
  # Returns the last modification time before the document got indexed.
  #   >> doc.pretty_mtime
  #   => "2008-05-09 09:39:51"
  def pretty_mtime
    from_index[:modified].sub(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/,'\1-\2-\3 \4:\5:\6')
  end

  # Returns the last modification time before the document got indexed, as YYYYMMDDHHMMSS integer.
  #   >> doc.mtime
  #   => 20080509093951
  def mtime
    from_index[:modified].to_i
  end

  # Returns found language, if any.
  def language
    from_index[:language]
  end

  # Returns matching score as a percentage, e.g. 56.3%
  def pretty_score
    "%3.1f%" % (@score*100)
  end

  # Indexing fields that are shared between every document.
  def self.default_fields_for(complete_path)
    doc=Document.new(complete_path)
    {
      :complete_path      => complete_path,
      :probably_unique_id => complete_path.base26_hash,
      :alias_path         => doc.alias_path,
      :filename           => File.basename(complete_path),
      :basename           => File.basename(complete_path, File.extname(complete_path)).gsub(/_/,' '),
      :filetype           => File.extname(complete_path),
      :modified           => File.mtime(complete_path).strftime("%Y%m%d%H%M%S")
    }
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

  # Returns true unless content is empty
  def has_content?
    cached !~ /^\s*$/
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

  # Retrieves the document from the index.
  # Useful to get meta-info about it.
  def from_index
    Indexer.index[probably_unique_id]
  end

  def self.find_by_unique_id(probably_unique_id)
    new(Indexer.index[probably_unique_id][:complete_path])
  end

  def in_indexed_directory?
    !indexed_directory.nil?
  end

  # Returns the IndexedDirectory in which the Document is included.
  # Returns nil if no corresponding dir is found.
  def indexed_directory
    Picolena::IndexedDirectories.keys.find{|indexed_dir|
      dirname.starts_with?(indexed_dir)
    }
  end

  # Raises unless @complete_path is the path of an existing file
  def validate_existence_of_file
    raise Errno::ENOENT, @complete_path unless file?
  end

  # Raises unless @complete_path is included in an indexed_directory.
  # It prevents end user to get information about non-indexed sensitive files.
  def validate_in_indexed_directory
    raise ArgumentError, "required document is not in indexed directory" unless in_indexed_directory?
  end
end
