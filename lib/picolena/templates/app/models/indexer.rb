# Indexer is used to index (duh!) documents contained in IndexedDirectories
# It can create, update, delete and prune the index, and take care that only
# one IndexWriter exists at any given time, even when used in a multi-threaded
# way.
#
# Related configuration files are written as .yml files in /config/custom/:
#   indexed_directories.yml
#   indexing_performance.yml
#   picolena.rb
# They control the indexing performance, which directories should be indexed
# , which files should be ignored and if language recognition is to be used.
#
# TODO: specs to test if rake index:update works the way it should

require 'indexer_logger'
require 'timeout'
class Indexer
  class << self
    # Finds every document included in IndexedDirectories, parses them with
    # PlainTextExtractor and adds them to the index.
    #
    # Updates the index unless remove_first parameter is set to true, in which
    # case it removes the index first before re-creating it.
    def index_every_directory(remove_first=false)
      clear! if remove_first
      lock!
      @from_scratch = remove_first
      logger.start_indexing
      Picolena::IndexedDirectories.each{|dir, alias_dir|
        index_directory_with_multithreads(dir)
      }
      logger.debug "Now optimizing index"
      index.optimize
      unlock!
      logger.show_report
    end

    # Indexes a given directory, using @@threads_number threads.
    # To do so, it retrieves a list of every included document, cuts it in
    # @@threads_number chunks, and create a new indexing thread for every chunk.
    def index_directory_with_multithreads(dir)
      logger.debug "Indexing #{dir}, #{Picolena::IndexingConfiguration[:threads_number]} threads"
      indexing_list=Dir[File.join(dir,"**/*")].select{|filename|
        File.file?(filename) && File.basename(filename) !~ Picolena::ToIgnore
      }

      logger.documents_number = indexing_list.size

      indexing_list_chunks=indexing_list.in_transposed_slices(Picolena::IndexingConfiguration[:threads_number])
      prepare_multi_threads_environment

      indexing_list_chunks.each_with_thread{|thread_number, chunk|
        chunk.each{|complete_path|
          add_or_update_file(complete_path,thread_number)
        }
      }
    end

    # Retrieves content and language from a given document, and adds it to the index.
    # Since Document#probably_unique_id is used as index :key, no document will be added
    # twice to the index, and the old document will just get updated.
    #
    # If for some reason (no content found or no defined PlainTextExtractor), content cannot
    # be found, some basic information about the document (mtime, filename, complete_path)
    # gets indexed anyway.
    def add_or_update_file(complete_path, thread_number)
      begin
        Timeout::timeout(60) do
          document=Document.find_by_complete_path(complete_path)
          if document then
            if document.supported? then
              if document.has_been_modified? then
                # If the document exists & has content that might have been modified, update it
                document.extract_doc_info!(:truncate)
                document.save
                logger.add_document(document, :update, thread_number)
                index << document.to_ferret_doc
              else
                # The document hasn't been modified, move along
                logger.ignore "Identical", complete_path, thread_number
              end
            else
             # The document isn't supported, move along
             logger.ignore "Ignoring", complete_path, thread_number
            end
          else
            # The document has not been indexed so far, create it and extract its content if supported
            document=Document[complete_path]
            if document.supported? then
              logger.add_document document, false, thread_number
            else
              logger.reject_document document, thread_number
            end
            index << document.to_ferret_doc
          end
        end
      rescue Exception => e
        # TODO: If TimeOut exceeded, ensure that at least some information about Document is written in DB
        # TODO: If TimeOut exceeded, ensure that no tmp file resides in /tmp
        logger.exception complete_path, e, thread_number
      end
    end

    # Ensures index is closed, and removes every index file for RAILS_ENV.
    def clear!(db_as_well=true)
      Document.destroy_all if db_as_well
      close
      Dir.glob(File.join(Picolena::IndexSavePath,'**/*')).each{|f| FileUtils.rm(f) if File.file?(f)}
    end

    # Closes the index and
    # ensures that a new Index is instantiated next time index is called.
    def close
      @@index.close rescue nil
      @@index = nil
    end
    
    # Checks for indexed files that are missing from filesytem
    # and removes them from index & DB
    def prune_index
#     missing_files=index_time_dbm_file.reject{|filename,itime| File.exists?(filename) && Picolena::IndexedDirectories.any?{|dir,alias_path| filename.starts_with?(dir)}}
#     missing_files.each{|filename, itime|
#       index.writer.delete(:complete_path, filename)
#       index_time_dbm_file.delete(filename)
#       logger.debug "Removed : #{filename}"
#     }
#     index.optimize
    end

    # Only one IndexWriter should be instantiated.
    # If one index already exists, returns it.
    # Creates it otherwise.
    def index
      @@index ||= Ferret::Index::Index.new(default_index_params)
    end

    # Creates the index unless it already exists.
    def ensure_index_existence
      index_every_directory(:remove_first) unless index_exists? or RAILS_ENV=="production"
    end

    # Returns how many files are indexed.
    def size
      index.size
    end

    # Returns the time at which the index was last created/updated.
    # Returns "none" if it doesn't exist.
    def last_update
      "none"
    end
    
    # Returns the time at which the reload file was last touched.
    # Useful to know if other processes have modified the shared index,
    # and if the Indexer should be reloaded.
    def reload_file_mtime
      touch_reload_file! unless File.exists?(reload_file)
      File.mtime(reload_file)
    end
    
    def locked?
      File.exists?(lock_file)
    end

    def recreate_from_database!
      clear!(db_as_well=false)
      lock!
      #TODO: Batched find will be useful
      Document.find(:all).each{|document|
        index << document.to_ferret_doc
      }
      index.optimize
      unlock!
    end

    private
    
    def touch_reload_file!
      FileUtils.touch(reload_file)
      # To ensure that every process can touch reload_file, even if Picolena
      # is launched as a special user.
      FileUtils.chmod(0666, reload_file)
    end
    
    def reload_file
      FileUtils.mkpath Picolena::MetaIndexPath
      File.join(Picolena::MetaIndexPath,'reload')
    end
    
    def lock!
      FileUtils.touch(lock_file)
    end
    
    def unlock!
      FileUtils.rm(lock_file)
      # Forces Finder.index to be reloaded.
      touch_reload_file!
    end
    
    def lock_file
      FileUtils.mkpath Picolena::MetaIndexPath
      File.join(Picolena::MetaIndexPath,'lock')
    end

    def logger
      @@logger ||= IndexerLogger.new
    end
    
    def index_exists?
      index_filename and File.exists?(index_filename)
    end

    def index_filename
      Dir.glob(File.join(Picolena::IndexSavePath,'*.cfs')).first
    end

    def default_index_params
      {
        :path        => Picolena::IndexSavePath,
        :analyzer    => Picolena::Analyzer,
        :field_infos => default_field_infos,
        # Great way to ensure that no file is indexed twice!
        :key         => :probably_unique_id
        }.merge Picolena::IndexingConfiguration
    end

    def default_field_infos
      returning Ferret::Index::FieldInfos.new do |field_infos|
        field_infos.add_field(:probably_unique_id, :store => :no,  :index => :untokenized)
        field_infos.add_field(:complete_path,      :store => :yes, :index => :untokenized)
        field_infos.add_field(:cache_content,      :store => :yes, :index => :yes)
        field_infos.add_field(:alias_path,         :store => :no,  :index => :yes, :boost => 0.5)
        field_infos.add_field(:basename,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:filename,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:filetype,           :store => :no,  :index => :yes, :boost => 1.5)
        field_infos.add_field(:cache_mtime,        :store => :yes, :index => :untokenized)
        field_infos.add_field(:language,           :store => :yes, :index => :untokenized)
      end
    end
    
    def prepare_multi_threads_environment
      # It initializes the Index before launching multithreaded
      # indexing. Otherwise, two threads could try to instantiate
      # an IndexWriter at the same time, and get a
      #  Ferret::Store::Lock::LockError
      index
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
