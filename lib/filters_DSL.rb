require 'tmpdir'

#Module used to define Filters with DSL
#   PlainText.extract {
#      from :doc, :dot
#      as "application/msword"
#      aka "Microsoft Office Word document"
#      with "antiword SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
#      which_should_for_example_extract 'district heating', :from => 'Types of malfunction in DH substations.doc'
#   }
module PlainText
  @@filters=[]
  
  #returns every already defined filter
  def self.filters
    @@filters
  end
  
  #returns every required dependency for every defined filter
  def self.filter_dependencies
    filters.collect{|filter| filter.dependencies}.flatten.compact.uniq.sort
  end
  
  #defines a new Filter with DSL
  def self.extract(&block)
    filter = Filter.new
    filter.instance_eval(&block)
    filters<<filter
    MimeType.add(filter.exts,filter.mime_name)
  end
  
  #finds which filter should be used for a given file, according to its extension
  def self.find_filter_for(filename)
    ext=File.ext_as_sym(filename)
    filters.find{|filter| filter.exts.include?(ext)} || raise(ArgumentError, "no convertor for #{filename}")
  end
  
  #launches filter on given file and outputs plain text result
  def self.extract_content_from(source)
    @@temp_file ||= File.join(Dir::tmpdir,"ferret_#{Time.now.to_i}")
    FileUtils.rm @@temp_file, :force => true
    find_filter_for(source).apply!(source,@@temp_file)
    File.read(@@temp_file)
  end
  
  #defined by DSL described in PlainText
  class Filter
    #DSL part
    attr_reader :exts, :mime_name, :description, :command, :content_and_file_examples
    
    def initialize
      @content_and_file_examples=[]   
    end
    
    def from(*exts)
      @exts=exts
    end
    
    def as(mime_name)
      @mime_name=mime_name
    end
    
    def aka(description)
      @description=description
    end
    
    def which_requires(*dependencies)
      @dependencies=dependencies
    end
    
    #parses command in order to know which programs are needed.
    #rspec will then check that every dependecy is installed on the system
    def dependencies
      if command.is_a?(String) then
        command.split(/\|\s*/).collect{|command_part| command_part.split(/ /).first}
      else
        @dependencies
      end
    end
    
    #used by rspec to test filters:
    #  which_should_for_example_extract 'in a pdf file', :from => 'basic.pdf'
    #  or_extract 'some other stuff inside another pdf file', :from => 'yet_another.pdf'
    #
    #this spec will pass if 'basic.pdf' and 'yet_another.pdf' are included in an indexed directory, if every dependency is installed,
    #and if plain text output from the filter applied to 'basic.pdf' and 'yet_another.pdf' respectively include 'in a pdf file' and 'some other stuff inside another pdf file' 
    def which_should_for_example_extract(content, file)
      @content_and_file_examples << [content,file[:from]]
    end
    
    #it allows to define specs in this way:
    #  which_should_for_example_extract 'Hello world!', :from => 'hello.rb'
    #  or_extract 'text inside!', :from => 'crossed.txt'
    alias_method :or_extract, :which_should_for_example_extract
    
    def with(commands_hash={},&block)
      platform=case RUBY_PLATFORM
        when /linux/
          :on_linux
        when /win/
          :on_windows
      end
      @command=commands_hash.invert[platform] || block
    end
    
    #conversion part
    def apply!(source,destination)
      return unless command
      if command.is_a?(String) then
        system(command.sub('SOURCE','"'<<source<<'"').sub('DESTINATION','"'<<destination<<'"'))
      else
        command.call(source,destination)
      end
      raise "missing #{cmd.split(' ').first} command" if $?.exitstatus == 127
      raise "failed to convert #{mime_name}: #{source}" unless $?.exitstatus == 0
    end
  end
end

## Loads every filter

Dir.glob(File.join(File.dirname(__FILE__),'filters/*.rb')).each{|filter|
  require filter
}

#puts PlainText.filters.inspect