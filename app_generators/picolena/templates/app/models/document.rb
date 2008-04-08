class Document
  attr_reader :complete_path
  attr_accessor :user, :score, :matching_content
  
  def initialize(complete_path)
    @complete_path=complete_path
    validate_existence_of_file
    validate_in_indexed_directory
  end
  
  def to_param
    id
  end
  
  def to_s
    filename
  end
  
  #Delegating properties to File::method_name(complete_path)
  [:dirname, :basename, :extname, :size?, :file?, :read, :ext_as_sym].each{|method_name|
    define_method(method_name){File.send(method_name,complete_path)}
  }
  alias_method :size, :size?
  alias_method :content, :read
  alias_method :filename, :basename
  
  def basename
    filename.chomp(extname)
  end
    
  def absolute_dirname
    Pathname.new(dirname).realpath.to_s
  end
  
  def alias_path
    original_dir=indexed_directory
    alias_dir=IndexedDirectories[original_dir]
    absolute_dirname.sub(original_dir,alias_dir)
  end
  
  def md5
    @md5=Digest::MD5.hexdigest(complete_path)
  end
  
  def supported?
    PlainText.supported_extensions.include?(self.ext_as_sym)
  end
  
  def content
    PlainText.extract_content_from(complete_path)
  end
  
  private
  
  def in_indexed_directory?
    !indexed_directory.nil?
  end
  
  def indexed_directory
    IndexedDirectories.keys.find{|indexed_dir|
      absolute_dirname.starts_with?(indexed_dir)
    }    
  end
  
  def validate_existence_of_file
    raise Errno::ENOENT, @complete_path unless file?
  end
  
  def validate_in_indexed_directory
    raise ArgumentError, "required document is not in indexed directory" unless in_indexed_directory?
  end
end