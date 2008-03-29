require 'filter_DSL'

module PlainText
  @@filters=[]
  
  #returns every defined filter
  def self.filters
    @@filters
  end
  
  #returns every required dependency for every defined filter
  def self.filter_dependencies
    @@dependencies||=filters.collect{|filter| filter.dependencies}.flatten.compact.uniq.sort
  end
  
  #returns every supported file extensions
  def self.supported_extensions
    @@supported_exts||=filters.collect{|filter| filter.exts}.flatten.compact.uniq
  end

  #finds which filter should be used for a given file, according to its extension
  def self.find_filter_for(filename)
    ext=File.ext_as_sym(filename)
    filter=filters.find{|filter| filter.exts.include?(ext)} || raise(ArgumentError, "no convertor for #{filename}")
    filter.source=filename
    filter
  end
  
  #launches filter on given file and outputs plain text result
  def self.extract_content_from(source)
    find_filter_for(source).extract_content
  end
  
  
  class Filter
    attr_accessor :source
    
    #parses command in order to know which programs are needed.
    #rspec will then check that every dependecy is installed on the system
    def dependencies
      if command.is_a?(String) then
        command.split(/\|\s*/).collect{|command_part| command_part.split(/ /).first}
      else
        @dependencies
      end
    end
    
    #Conversion part
    
    #destination method can be used by some conversion command that cannot output to stdout (example?)
    #a file containing plain text result will first be written by command, and then be read by extract_content.
    def destination
      require 'tmpdir'
      @@temp_file_as_destination ||= File.join(Dir::tmpdir,"ferret_#{Time.now.to_i}")
    end
    
    #Replaces generic command with specific source and destination (if specified) files
    def specific_command
      command.sub('SOURCE','"'<<source<<'"').sub('DESTINATION','"'<<destination<<'"')
    end
    
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
end