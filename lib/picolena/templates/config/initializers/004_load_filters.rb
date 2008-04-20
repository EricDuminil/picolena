require 'core_exts'
require 'plain_text_extractor_DSL'

Dir.glob(File.join(RAILS_ROOT,'lib/plain_text_extractors/*.rb')).each{|extractor|
  require extractor
}
