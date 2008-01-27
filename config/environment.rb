# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|  
  # We don't need no stinkin' AR!
  # Ferret backs us up.
  config.frameworks -= [ :active_record ]
end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below

require 'ferret'
require 'paginator'
require 'pathname'

Ferret.locale = "en_US.UTF-8"
Ferret::Search::FuzzyQuery.default_min_similarity=0.6

# Which language should be used?
# English (:en) & German (:de) are supported
Globalite.language = :en