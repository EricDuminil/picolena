class Indexer
  Exclude          = /(Thumbs\.db)/
  MaxThreadsNumber = 5
  
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
        index_directory_with_multithreads(dir)
      }
      # FIXME: with those 2 lines,
      writer.optimize
      writer.close
      # launching Indexer.index_every_directory twice in a row
      # would raise a SEGFAULT:
      # picolena/lib/picolena/templates/app/models/indexer.rb:27: [BUG] Segmentation fault
      # ruby 1.8.6 (2007-06-07) [i486-linux]
      #
      # Aborted (core dumped)
    end
    
    def index_directory_with_multithreads(dir)
      log :debug => "Indexing #{dir}, #{MaxThreadsNumber} multithreads"
      
      @indexing_list=Dir[File.join(dir,"**/*")].select{|filename|
        File.file?(filename) && filename !~ Exclude
      }
      
      MaxThreadsNumber.threads{launch_indexing_chain(@indexing_list)}
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
    
    def launch_indexing_chain(indexing_list)
      return if indexing_list.empty?
      add_or_update_file(indexing_list.shift)
      launch_indexing_chain(indexing_list)
    end
    
    def log(hash)
      hash.each{|level,message|
        puts "#{level} -> #{message}"
        IndexerLogger.send(level,message)
      }
    end  
  end
end