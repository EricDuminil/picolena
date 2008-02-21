module PlainText
  @@filters=[]
  
  def self.filters
    @@filters
  end
  
  def self.extract(&block)
    filter = Filter.new
    filter.instance_eval(&block)
    filters<<filter
    MimeType.add(filter.exts,filter.mime_name)
  end
  
  def self.find_filter_for(filename)
    ext=File.ext_as_sym(filename)
    filters.find{|filter| filter.exts.include?(ext)} || raise(ArgumentError, "no convertor for #{filename}")
  end
  
  class Filter
    attr_reader :exts, :mime_name, :description, :command
    
    def from(*exts)
      @exts=exts
    end
    
    def as(mime_name)
      @mime_name=mime_name
    end
    
    def aka(description)
      @description=description
    end
    
    def with(commands_hash={},&block)
      platform=case RUBY_PLATFORM
        when /linux/
          :on_linux
        when /win/
          :on_windows
      end
      @command=commands_hash.invert[platform] || block
    end
    
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