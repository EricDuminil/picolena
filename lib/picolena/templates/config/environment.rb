%w(rubygems paginator fileutils pathname logger thread).each{|lib| require lib}

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

IndexerLogger=Logger.new($stdout)

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # We don't need no stinkin' AR!
  # Ferret backs us up.
  config.frameworks -= [ :active_record ]
end
