class MimeType
  @@all=[]
  def self.all
    @@all
  end
  
  def self.add(exts,mime_name)
    all<<new(exts,mime_name)
  end
  
  attr_reader :exts, :name
  
  def initialize(exts,mime_name)
    @exts,@name=exts,mime_name
  end
end

class File
  def self.ext_as_sym(filename)
    File.extname(filename).sub(/^\./,'').downcase.to_sym
  end
  
  def self.mime(filename)
    ext=ext_as_sym(filename)
    m=MimeType.all.find{|m| m.exts.include?(ext)}
    m ? m.name : 'application/octet-stream'
  end
  
  def self.encoding(source)
    parse_for_charset="grep -io charset=[a-z0-9\\-]* | sed 's/charset=//i'"
    if File.extname(source)[0,4]==".htm" then
      enc=%x{head -n20 \"#{source}\" | #{parse_for_charset}}.chomp      
    else
      enc=%x{file -i \"#{source}\"  | #{parse_for_charset}}.chomp
    end
    #iso-8859-15 should be used instead of iso-8859-1, for € char
    case enc
     when "iso-8859-1"
       "iso-8859-15"
     when "unknown"
       ""
     else
       enc
     end
  end
  
  def self.read_and_remove(filename)
    content=read(filename)
    FileUtils.rm filename, :force=>true
    content
  end
end


# TODO: Move those 2 methods to some logger.
def puts_to_stderr_if_dev(string)
  $stderr.puts string if RAILS_ENV=="development"
end

def puts_to_stderr_if_not_test(string)
  $stderr.puts string if RAILS_ENV!="test"
end
