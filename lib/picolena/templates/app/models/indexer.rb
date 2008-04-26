class Indexer
  # This regexp defines which files should *not* be indexed.
  @@exclude          = /(Thumbs\.db)/
  # Number of threads that will be used during indexing process
  @@threads_number = 8
  
  cattr_reader :do_not_disturb_while_indexing

  class << self
    def index_every_directory(remove_first=false)
      @@do_not_disturb_while_indexing=true
      clear! if remove_first
      @from_scratch = remove_first
      # Forces Finder.searcher and Finder.index to be reloaded, by removing them from the cache.
      Finder.reload!
      log :debug => "Indexing every directory"
      start=Time.now
      Picolena::IndexedDirectories.each{|dir, alias_dir|
        index_directory_with_multithreads(dir)
      }
      log :debug => "Now optimizing index"
      index.optimize
      @@do_not_disturb_while_indexing=false
      log :debug => "Indexing done in #{Time.now-start} s."
    end

    def index_directory_with_multithreads(dir)
      log :debug => "Indexing #{dir}, #{@@threads_number} threads"

      indexing_list=Dir[File.join(dir,"**/*")].select{|filename|
        File.file?(filename) && filename !~ @@exclude
      }

      indexing_list_chunks=indexing_list.in_transposed_slices(@@threads_number)
      
      prepare_multi_threads_environment
      
      indexing_list_chunks.each_with_thread{|chunk|
        chunk.each{|complete_path|
          last_itime=index_time_dbm_file[complete_path]
          if @from_scratch || !last_itime || File.mtime(complete_path)> Time._load(last_itime) then
            add_or_update_file(complete_path)
          else
            log :debug => "Identical : #{complete_path}"
          end
          index_time_dbm_file[complete_path] = Time.now._dump
        }
      }
    end

    def add_or_update_file(complete_path)
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
      index << document
    end

    # Ensures index is closed, and removes every index file for RAILS_ENV.
    def clear!(all=false)
      close
      to_remove=all ? Picolena::IndexesSavePath : Picolena::IndexSavePath
      Dir.glob(File.join(to_remove,'**/*')).each{|f| FileUtils.rm(f) if File.file?(f)}
    end

    # Closes the index and
    # ensures that a new Index is instantiated next time index is called.
    def close
      @@index.close rescue nil
      # Ferret will SEGFAULT otherwise.
      @@index = nil
    end
    
    
    # Checks for indexed files that are missing from filesytem
    # and removes them from index & dbm file.
    def prune_index
      missing_files=index_time_dbm_file.reject{|filename,itime| File.exists?(filename)}
      missing_files.each{|filename, itime|
        index.writer.delete(:complete_path, filename)
        index_time_dbm_file.delete(filename)
        log :debug => "Removed : #{filename}"
      }
      index.optimize
    end

    # Only one IndexWriter should be instantiated.
    # If one index already exists, returns it.
    # Creates it otherwise.
    def index
      @@index ||= Ferret::Index::Index.new(default_index_params)
    end

    def ensure_index_existence
      index_every_directory(:remove_first) unless index_exists? or RAILS_ENV=="production"
    end

    # Returns how many files are indexed.
    def size
      index.size
    end

    private
    
    # Copied from Ferret book, By David Balmain
    def index_time_dbm_file
      @@dbm_file ||= DBM.open(File.join(Picolena::IndexSavePath, 'added_at'))
    end

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
      {
        :path        => Picolena::IndexSavePath,
        :analyzer    => Picolena::Analyzer,
        :field_infos => default_field_infos,
        # Great way to ensure that no file is indexed twice!
        :key         => :probably_unique_id
        }
    end

    def default_field_infos
      returning Ferret::Index::FieldInfos.new do |field_infos|
        field_infos.add_field(:complete_path,      :store => :yes, :index => :untokenized)
        field_infos.add_field(:content,            :store => :yes, :index => :yes)
        field_infos.add_field(:basename,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:filename,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:filetype,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:modified,           :store => :yes, :index => :untokenized)
        field_infos.add_field(:probably_unique_id, :store => :no,  :index => :untokenized)
        field_infos.add_field(:language,           :store => :yes, :index => :yes)
      end
    end
    
    def prepare_multi_threads_environment
      # It initializes the Index before launching multithreaded
      # indexing. Otherwise, two threads could try to instantiate
      # an IndexWriter at the same time, and get a
      #  Ferret::Store::Lock::LockError
      index
      # Opens dbm file to dump indexing time.
      index_time_dbm_file
      # NOTE: is it really necessary?
      # ActiveSupport sometime raises
      #  Expected Object is NOT missing constant
      # without.
      Document
      Finder
      Query
      PlainTextExtractor
    end
  end
end