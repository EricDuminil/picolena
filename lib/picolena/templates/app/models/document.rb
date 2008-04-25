# Document class retrieves information from filesystem and the index for any given document.
class Document
  attr_reader :complete_path
  attr_accessor :user, :score, :matching_content
  
  def initialize(path)
    #To ensure @complete_path is an absolute direction.
    @complete_path=File.expand_path(path)
    validate_existence_of_file
    validate_in_indexed_directory
  end
  
  #Delegating properties to File::method_name(complete_path)
  [:dirname, :basename, :extname, :size?, :file?, :read, :ext_as_sym].each{|method_name|
    define_method(method_name){File.send(method_name,complete_path)}
  }
  alias_method :size, :size?
  alias_method :filename, :basename
  alias_method :to_s, :basename
  
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
    PlainTextExtractor.supported_extensions.include?(self.ext_as_sym)
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
  
  # FIXME: Not just date anymore.
  # Returns the last modification date before the document got indexed.
  # Useful to know how old a document is, and to which version the cache corresponds.
  def date
    from_index[:modified].sub(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/,'\1-\2-\3 \4:\5:\6')
  end
  
  def mtime
    from_index[:modified].to_i
  end
  
  # Returns language.
  def language
    from_index[:language]
  end
  
  # Fields that are shared between every document.
  def self.default_fields_for(complete_path)
    {
      :complete_path      => complete_path,
      :probably_unique_id => complete_path.base26_hash,
      :filename           => File.basename(complete_path),
      :basename           => File.basename(complete_path, File.extname(complete_path)).gsub(/_/,' '),
      :filetype           => File.extname(complete_path),
      :modified           => File.mtime(complete_path).strftime("%Y%m%d%H%M%S")
    }             
  end
  
  private
  
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
  
  def indexed_directory
    Picolena::IndexedDirectories.keys.find{|indexed_dir|
      dirname.starts_with?(indexed_dir)
    }    
  end
  
  def validate_existence_of_file
    raise Errno::ENOENT, @complete_path unless file?
  end
  
  def validate_in_indexed_directory
    raise ArgumentError, "required document is not in indexed directory" unless in_indexed_directory?
  end
end