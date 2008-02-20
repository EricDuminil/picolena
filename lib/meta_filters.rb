module PlainText
  @@filters||=[]
  
  def self.filters
    @@filters
  end
  
  def self.filter(&block)
    filter = Filter.new
    filter.instance_eval(&block)
    filters<<filter
  end
  
  class Filter
    attr_reader :exts, :mime, :description, :commands 
    
    def convert(*exts)
      @exts=exts
    end
    
    def as(mime)
      @mime=mime
    end
    
    def aka(description)
      @description=description
    end
    
    def with(commands_hash)
      @commands=commands_hash.invert
    end
  end
end

## Loads every filter

Dir.glob(File.join(File.dirname(__FILE__),'filters/*.rb')).each{|f|
  require f
}

puts PlainText.filters.inspect