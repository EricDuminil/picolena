module RubiGen
  module Commands
    class Create
      def rake(task_name)
        logger.rake task_name
        Dir.chdir(destination_path('')){
         system("rake #{task_name}")
        }
      end

      def mirror(relative_source,relative_destination)
        logger.mirror "#{relative_source} -> #{relative_destination}"
        source      = destination_path(relative_source)
        destination = destination_path(relative_destination)
        FileUtils.cp_r source, destination
      end

      def clean
        FileUtils.remove_entry_secure destination_path('')
      end
    end
  end
end
