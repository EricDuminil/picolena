module Filter
  def self.which
    puts "Been here!"
  end
end


## Loads every filter

Dir.glob(File.join(File.dirname(__FILE__),'filters/*.rb')).each{|f|
  require f
}