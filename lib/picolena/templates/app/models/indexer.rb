#require 'singleton'

class Indexer
  Exclude = /(Thumbs\.db)/
  
  #include Singleton
  def self.index_every_directory
    log :debug => "Indexing every directory"
    IndexedDirectories.each{|dir, alias_dir|
      index_directory(dir)
    }
  end
  
  def self.index_directory(dir)
    log :debug => "Indexing #{dir}"
    Dir.glob(File.join(dir,"**/*")){|filename|
      if File.file?(filename) && filename !~ Exclude then
        index_file(filename)
      end
    }
  end
  
  def self.index_file(filename)
    log :debug => "Indexing #{filename}"
  end
  
  private
  
  def self.log(hash)
    hash.each{|level,message|
      puts "#{level} -> #{message}"
      IndexerLogger.send(level,message)
    }
  end
end