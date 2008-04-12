class Indexer
  Exclude = /(Thumbs\.db)/
  
  def self.index_every_directory
    log :debug => "Indexing every directory"
    begin
      IndexedDirectories.each{|dir, alias_dir|
        index_directory(dir)
      }
      writer.optimize
    ensure
      writer.close
    end
  end
  
  def self.index_directory(dir)
    log :debug => "Indexing #{dir}"
    Dir.glob(File.join(dir,"**/*")){|filename|
      if File.file?(filename) && filename !~ Exclude then
        mime_type = File.mime(filename)
        begin
          index_file(filename, mime_type)
        rescue => e
          log :debug => "indexing without content: #{e.message}"
          index_file(filename)
        end
      end
    }
  end
  
  def self.index_file(filename,mime_type = nil)
    log :debug => "Indexing #{filename}"
    
    complete_path=File.expand_path(filename)
    
    fields = {
      :complete_path=> complete_path,
      :probably_unique_id => complete_path.base26_hash,
      :file => File.basename(filename),
      :basename => File.basename(filename, File.extname(filename)).gsub(/_/,' '),
      :filetype => File.extname(filename),
      :date => File.mtime(filename).strftime("%Y%m%d%H%M")
    }
    
    if mime_type then
      text = PlainText.extract_content_from(filename)
      raise "empty document #{filename}" if text.strip.empty?
      fields[:content] = text
    end
    
    writer << fields
  end
  
  def self.writer
    @@writer ||= IndexWriter.new
  end
  
  def self.reset!
    log :debug => "Resetting Index"
    @@writer=nil
    IndexWriter.remove
  end
  
  private
  
  def self.log(hash)
    hash.each{|level,message|
      puts "#{level} -> #{message}"
      #IndexerLogger.send(level,message)
    }
  end
end