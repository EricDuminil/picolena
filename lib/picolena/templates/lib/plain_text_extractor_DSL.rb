# Defines plain text extractors with DSL
# For example, to convert "Microsoft Office Word document" to plain text
#  PlainTextExtractor.new {
#    every :doc, :dot
#    as "application/msword"
#    aka "Microsoft Office Word document"
#    with "antiword SOURCE" => :on_linux, "some other command" => :on_windows
#    which_should_for_example_extract 'district heating', :from => 'Types of malfunction in DH substations.doc'
#    or_extract 'Basic Word template for Picolena specs', :from => 'office2003-word-template.dot'
#  }

module PlainTextExtractorDSL
  attr_reader :exts, :mime_name, :description, :command, :content_and_file_examples

  def initialize(&block)
    @content_and_file_examples=[]
    self.instance_eval(&block)
    PlainTextExtractor.add(self)
    MimeType.add(self.exts,self.mime_name)
  end

  def every(*exts)
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

  #used by rspec to test extractors:
  #  which_should_for_example_extract 'in a pdf file', :from => 'basic.pdf'
  #  or_extract 'some other stuff inside another pdf file', :from => 'yet_another.pdf'
  #
  #this spec will pass if 'basic.pdf' and 'yet_another.pdf' are included in an indexed directory, if every dependency is installed,
  #and if plain text output from the extractor applied to 'basic.pdf' and 'yet_another.pdf' respectively include 'in a pdf file' and 'some other stuff inside another pdf file'
  def which_should_for_example_extract(content, file)
    @content_and_file_examples << [content,file[:from]]
  end

  #it allows to define specs in this way:
  #  which_should_for_example_extract 'Hello world!', :from => 'hello.rb'
  #  or_extract 'text inside!', :from => 'crossed.txt'
  alias_method :or_extract, :which_should_for_example_extract

  def with(command_as_hash_or_string=nil,&block)
    #TODO: Find a better way to manage platforms, and include OS X, Vista, BSD...
    platform=case RUBY_PLATFORM
    when /linux/
      :linux
    when /win/
      :windows
    when /darwin/
      :mac_os
    end
    @command=case command_as_hash_or_string
    when String
      command_as_hash_or_string
    when Hash
      # Allows to write
      #     with "pdftotext -enc UTF-8 SOURCE -" => :on_linux_and_mac_os,
      #          "some other command" => :on_windows
      #
      # On linux and mac_os platforms, it returns "pdftotext -enc UTF-8 SOURCE -",
      # on windows, it returns "some other command"
      #
      # If commands for linux & mac os were different :
      #     with "some command"        => :on_linux,
      #          "another command"     => :on_mac_os,
      #          "yet another command" => :on_windows
      #
      #TODO: Make it clearer and more robust.
      #NOTE: What to do when no command is defined for a given platform?
      command_as_hash_or_string.invert.find{|platforms,command|
        platforms.to_s.split(/_?and_?/i).collect{|on_platform| on_platform.sub(/on_/,'').to_sym}.include?(platform)
      }.last.dup
    else
      block || raise("No command defined for this extractor: #{description}")
    end
    # TODO, replace it with Open3 or something.
    @command<<' 2>/dev/null' if (@command.is_a?(String) && platform.to_s=~/(linux|mac_os)/ && !@command.include?('|'))
  end
end
