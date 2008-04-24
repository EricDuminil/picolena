class Indexer
  # This regexp defines which files should *not* be indexed.
  @@exclude          = /(Thumbs\.db)/
  # Number of threads that will be used during indexing process
  @@max_threads_number = 8
  
  class << self
    def index_every_directory(remove_first=false)
      clear! if remove_first
      # Forces Finder.searcher and Finder.index to be reloaded, by removing them from the cache.
      Finder.reload!
      log :debug => "Indexing every directory"
      start=Time.now
      Picolena::IndexedDirectories.each{|dir, alias_dir|
        index_directory_with_multithreads(dir)
      }
      log :debug => "Now optimizing index"
      writer.optimize
      log :debug => "Indexing done in #{Time.now-start} s."
    end
    
    def index_directory_with_multithreads(dir)
      threads_number = @@max_threads_number
      log :debug => "Indexing #{dir}, #{threads_number} thread(s)"
      
      indexing_list=Dir[File.join(dir,"**/*")].select{|filename|
        File.file?(filename) && filename !~ @@exclude
      }
      
      indexing_list_chunks=indexing_list.in_transposed_slices(threads_number)
      
      # It initializes an IndexWriter before launching multithreaded
      # indexing. Otherwise, two threads could try to instantiate
      # an IndexWriter at the same time, and get a
      #  Ferret::Store::Lock::LockError
      writer
      
      indexing_list_chunks.each_with_thread{|chunk|
        chunk.each{|filename|
          add_file(filename)
        }
      }
    end
    
    def add_file(complete_path)
      default_fields = Document.default_fields_for(complete_path)
      begin
        document = PlainTextExtractor.extract_content_and_language_from(complete_path)
        raise "empty document #{complete_path}" if document[:content].strip.empty?
        document.merge! default_fields
        log :debug => ["Added : #{complete_path}",document[:language] ? " (#{document[:language]})" : ""].join
      rescue => e
        log :debug => "\tindexing without content: #{e.message}"
        document = default_fields
      end
      writer << document
    end
    
    # Ensures writer is closed, and removes every index file for RAILS_ENV.
    def clear!(all=false)
      close
      to_remove=all ? Picolena::IndexesSavePath : Picolena::IndexSavePath
      Dir.glob(File.join(to_remove,'**/*')).each{|f| FileUtils.rm(f) if File.file?(f)}
    end
    
    # Closes the writer and
    # ensures that a new IndexWriter is instantiated next time writer is called.
    def close
      @@writer.close rescue nil
      # Ferret will SEGFAULT otherwise.
      @@writer = nil
    end
    
    # Only one IndexWriter should be instantiated.
    # If one already exists, returns it.
    # Creates it otherwise.
    def writer
      @@writer ||= Ferret::Index::IndexWriter.new(default_index_params)
    end
    
    def index
      Ferret::Index::Index.new(default_index_params)  
    end
    
    def ensure_index_existence
      index_every_directory(:remove_first) unless index_exists? or RAILS_ENV=="production"
    end
    
    private
    
    def index_exists?
      index_filename and File.exists?(index_filename)
    end
    
    def index_filename
      Dir.glob(File.join(Picolena::IndexSavePath,'*.cfs')).first
    end

    def log(hash)
      hash.each{|level,message|
        IndexerLogger.send(level,message)
      }
    end
    
    def default_index_params
      {:path => Picolena::IndexSavePath, :analyzer => Picolena::Analyzer, :field_infos => default_field_infos}
    end
    
    def default_field_infos
      returning Ferret::Index::FieldInfos.new do |field_infos|
        field_infos.add_field(:complete_path,      :store => :yes, :index => :untokenized)
        field_infos.add_field(:content,            :store => :yes, :index => :yes)
        field_infos.add_field(:basename,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:filename,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:filetype,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:modified,           :store => :yes, :index => :untokenized)
        field_infos.add_field(:probably_unique_id, :store => :no,  :index => :yes)
        field_infos.add_field(:language,           :store => :yes, :index => :yes)
      end
    end
  end
end