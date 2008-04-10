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

class String
  # Creates a "probably unique" id with the desired length, composed only of lowercase letters.
  def base26_hash(length=HashLength)
    Digest::MD5.hexdigest(self).to_i(16).to_s(26).tr('0-9a-p', 'a-z')[-length,length]
  end
end

class File
  def self.ext_as_sym(filename)
    File.extname(filename).sub(/^\./,'').downcase.to_sym rescue :no_extension
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
