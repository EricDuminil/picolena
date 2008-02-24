#Module used to define Filters with DSL
#For example, to convert "Microsoft Office Word document" to plain text
#   PlainText.extract {
#      from :doc, :dot
#      as "application/msword"
#      aka "Microsoft Office Word document"
#      with "antiword SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
#      which_should_for_example_extract 'district heating', :from => 'Types of malfunction in DH substations.doc'
#   }
module PlainText  
  #defines a new Filter with DSL
  def self.extract(&block)
    filter = Filter.new
    filter.instance_eval(&block)
    @@filters<<filter
    MimeType.add(filter.exts,filter.mime_name)
  end
  
  #defined by DSL described in PlainText
  class Filter
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
    
    def with(command_as_hash_or_string=nil,&block)
      platform=case RUBY_PLATFORM
        when /linux/
          :on_linux
        when /win/
          :on_windows
      end
      @command=case command_as_hash_or_string
        when String
          command_as_hash_or_string
        when Hash
          #dup must be used, otherwise @command gets frozen. No idea why though....
          command_as_hash_or_string.invert[platform].dup
        else
          block || raise("No command defined for this filter: #{description}")
        end
      @command<<' 2>/dev/null' if (@command.is_a?(String) && platform==:on_linux)
    end
  end
end