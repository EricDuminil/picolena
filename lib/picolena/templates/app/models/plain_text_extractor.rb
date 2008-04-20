require 'plain_text_extractor_DSL'

class PlainTextExtractor
  include PlainTextExtractorDSL
  @@extractors=[]
  class<<self 
    # Returns every defined extractor
    def all
      @@extractors
    end
    
    # Add an extractor to the extractors list
    def add(extractor)
      @@extractors<<extractor
    end
    
    # Calls block for each extractor
    def each(&block)
      all.each(&block)
    end
    
    # Returns every required dependency for every defined extractor
    def dependencies
      @@dependencies||=all.collect{|extractor| extractor.dependencies}.flatten.compact.uniq.sort
    end
    
    # Returns every supported file extensions
    def supported_extensions
      @@supported_exts||=all.collect{|extractor| extractor.exts}.flatten.compact.uniq
    end
    
    # Finds which extractor should be used for a given file, according to its extension
    # Raises if the file is unsupported. 
    def find_by_filename(filename)
      ext=File.ext_as_sym(filename)
      extractor=all.find{|extractor| extractor.exts.include?(ext)} || raise(ArgumentError, "no convertor for #{filename}")
      extractor.source=filename
      extractor
    end
    
    # Launches extractor on given file and outputs plain text result
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
      # If command is a String, launch it via system(command).
      if command.include?('DESTINATION') then
        # If command includes 'DESTINATION' keyword,
        # launches the command and returns the content of
        # DESTINATION file.
        system(specific_command)
        File.read_and_remove(destination)
      else
        # Otherwise, launches the command and returns STDOUT.
        IO.popen(specific_command){|io| io.read}
      end
    else
      # command is a Block.
      # Returns the result of command.call,
      # with source file as parameter.
      command.call(source)
    end
  end    
end