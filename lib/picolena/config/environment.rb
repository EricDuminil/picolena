%w(rubygems paginator fileutils pathname logger thread).each{|lib| require lib}

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Actually, we do need ActiveRecord!
  # Ferret does not back us up anymore.
  # config.frameworks -= [ :active_record ]
end

#Initialises Picolena module.
module Picolena
  VERSION='<%= version %>'
end
