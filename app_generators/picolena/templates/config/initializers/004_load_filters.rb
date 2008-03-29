require 'core_exts'
require 'filter'

Dir.glob(File.join(RAILS_ROOT,'lib/filters/*.rb')).each{|filter|
  require filter
}