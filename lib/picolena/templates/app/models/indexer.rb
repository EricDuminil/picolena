class Indexer
  Exclude = /(Thumbs\.db)/
  
  class << self
    def fields_for(filename)
      {
        :complete_path=> complete_path=File.expand_path(filename),
        :probably_unique_id => complete_path.base26_hash,
        :file => File.basename(filename),
        :basename => File.basename(filename, File.extname(filename)).gsub(/_/,' '),
        :filetype => File.extname(filename),
        :date => File.mtime(filename).strftime("%Y%m%d%H%M")
      }      
    end
    
    def index_every_directory
      log :debug => "Indexing every directory"
      
      IndexedDirectories.each{|dir, alias_dir|
        index_directory(dir)
      }
      writer.optimize
      writer.close
    end
    
    
    def index_directory(dir)
      log :debug => "Indexing #{dir}"
      
      Dir.glob(File.join(dir,"**/*")){|filename|
        index_file(filename, File.mime(filename)) if File.file?(filename) && filename !~ Exclude
      }
    end
    
    
    def index_file(filename,mime_type = nil)
      log :debug => "Indexing #{filename}"
      
      fields = fields_for(filename)
      
      if mime_type then
        begin 
          text = PlainText.extract_content_from(filename)
          raise "empty document #{filename}" if text.strip.empty?
          fields[:content] = text
        rescue => e
          log :debug => "indexing without content: #{e.message}"
        end
      end
      
      writer << fields
    end
    
    def writer
      @@writer ||= IndexWriter.new
    end
    
    def reset!
      log :debug => "Resetting Index"
      @@writer=nil
      IndexWriter.remove
    end
    
    private
    
    def log(hash)
      hash.each{|level,message|
        #puts "#{level} -> #{message}"
        IndexerLogger.send(level,message)
      }
    end  
  end
end