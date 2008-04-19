require 'filter_DSL'

class Filter
  include FilterDSL
  @@filters=[]
  class<<self 
  # Returns every defined filter
  def all
    @@filters
  end
  
  # Add a filter to the filters list
  def add(filter)
    @@filters<<filter
  end

  # Calls block for each filter
  def each(&block)
    all.each(&block)
  end
  
  # Returns every required dependency for every defined filter
  def dependencies
    @@dependencies||=all.collect{|filter| filter.dependencies}.flatten.compact.uniq.sort
  end
  
  # Returns every supported file extensions
  def supported_extensions
    @@supported_exts||=all.collect{|filter| filter.exts}.flatten.compact.uniq
  end

  # Finds which filter should be used for a given file, according to its extension
  # Raises if the file is unsupported. 
  def find_by_filename(filename)
    ext=File.ext_as_sym(filename)
    filter=all.find{|filter| filter.exts.include?(ext)} || raise(ArgumentError, "no convertor for #{filename}")
    filter.source=filename
    filter
  end
  
  # Launches filter on given file and outputs plain text result
  def extract_content_from(source)
    find_by_filename(source).extract_content
  end
  end

  
  
    attr_accessor :source
    
    # Parses command in order to know which programs are needed.
    # rspec will then check that every dependecy is installed on the system
    def dependencies
      if command.is_a?(String) then
        command.split(/\|\s*/).collect{|command_part| command_part.split(/ /).first}
      else
        @dependencies
      end
    end
    
    ## Conversion part
    
    # destination method can be used by some conversion command that cannot output to stdout (example?)
    # a file containing plain text result will first be written by command, and then be read by extract_content.
    def destination
      require 'tmpdir'
      @@temp_file_as_destination ||= File.join(Dir::tmpdir,"ferret_#{Time.now.to_i}")
    end
    
    # Replaces generic command with specific source and destination (if specified) files
    def specific_command
      command.sub('SOURCE','"'<<source<<'"').sub('DESTINATION','"'<<destination<<'"')
    end
   
    # Returns plain text content of source file
    def extract_content
      if command.is_a?(String) then
        if command.include?('DESTINATION') then
          system(specific_command)
          File.read_and_remove(destination)
        else
          IO.popen(specific_command){|io| io.read}
        end
      else
        command.call(source)
      end
    end    
end
