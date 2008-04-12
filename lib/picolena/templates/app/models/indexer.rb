class Indexer
  Exclude = /(Thumbs\.db)/
  
  class << self
    def fields_for(complete_path)
      {
        :complete_path      => complete_path,
        :probably_unique_id => complete_path.base26_hash,
        :file               => File.basename(complete_path),
        :basename           => File.basename(complete_path, File.extname(complete_path)).gsub(/_/,' '),
        :filetype           => File.extname(complete_path),
        :date               => File.mtime(complete_path).strftime("%Y%m%d%H%M%S")
      }      
    end    
        
    def index_every_directory(update=true)
      log :debug => "Indexing every directory"
      
      @update = update
      reset! unless update
      
      IndexedDirectories.each{|dir, alias_dir|
        index_directory(dir)
      }
      writer.optimize
      writer.close
    end
    
    def index_directory(dir)
      log :debug => "Indexing #{dir}"
      
      Dir.glob(File.join(dir,"**/*")){|filename|
        add_or_update_file(File.expand_path(filename)) if File.file?(filename) && filename !~ Exclude
      }
    end
    
    def add_or_update_file(complete_path)
      should_be_added = true
      if @update then
        log :debug =>  "What to do with #{complete_path} ?"
        occurences = reader.occurences_number(complete_path) 
        log :debug =>  "\tappears #{occurences} times in the index"
        case occurences
          when 0
          #Nothing to do here, the file will be added.
          when 1
          d=Document.find_by_complete_path(complete_path)
          if File.mtime(complete_path).strftime("%Y%m%d%H%M%S").to_i > d.mtime then
            log :debug => "\thas been modified"
            delete_file(complete_path)
          else
            should_be_added = false
            log :debug => "\thas not been modified. leaving it"
          end
        else
          delete_file(complete_path)
        end
      end
      add_file(complete_path) if should_be_added
    end
    
    def add_file(complete_path)
      log :debug => "Adding #{complete_path}"
      mime_type=File.mime(complete_path)
      fields = fields_for(complete_path)
      
      begin 
        text = PlainText.extract_content_from(complete_path)
        raise "\tempty document #{complete_path}" if text.strip.empty?
        fields[:content] = text
      rescue => e
        log :debug => "\tindexing without content: #{e.message}"
      end
      
      writer << fields
    end
    
    def writer
      @@writer ||= IndexWriter.new
    end
    
    def reader
      @@reader ||= IndexReader.new
    end
    
    def reset!
      log :debug => "Resetting Index"
      @@writer=nil
      @@reader=nil
      IndexWriter.remove
    end
    
    def delete_file(complete_path)
      log :debug => "\tRemoving from index"
      reader.delete_by_complete_path(complete_path)
    end
    
    private
    
    def log(hash)
      hash.each{|level,message|
        puts "#{level} -> #{message}"
        IndexerLogger.send(level,message)
      }
    end  
  end
end