module RubiGen
  module Commands
    class Create
      # Launch given Rake task in destination_path
      def rake(task_name)
        logger.rake task_name
        Dir.chdir(destination_path('')){
         system("rake #{task_name}")
        }
      end
      
      # Copy one directory to another in destination_path
      # Can be useful to duplicate index from development to production,
      # instead of indexing twice.
      def mirror(relative_source,relative_destination)
        logger.mirror "#{relative_source} -> #{relative_destination}"
        source      = destination_path(relative_source)
        destination = destination_path(relative_destination)
        FileUtils.cp_r source, destination
      end

      # Remove every file from destination_path
      # Useful to remove temporary dirs.
      def clean
        FileUtils.remove_entry_secure destination_path('')
      end
    end
  end
end
