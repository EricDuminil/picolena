### You should not modify this file if you'd like to customize your search engine.
### Please modify config/custom.rb instead.
### A template config/custom.rb will be created the first time you launch your web server.


custom_config_file = File.join(RAILS_ROOT, 'config/custom.rb')

File.open(custom_config_file,'w'){|custom|
  custom.puts <<-AUTO_CONF
### This file has been automatically generated the first time you launched your web server.
### You should add custom requirements here, they will be loaded everytime you restart the web server.


# Specify which locale should be used by Ferret
Ferret.locale = "en_US.UTF-8"

# Specify the default Levenshtein distance when using FuzzyQuery
# see http://ferret.davebalmain.com/api/classes/Ferret/QueryParser.html for more information.
Ferret::Search::FuzzyQuery.default_min_similarity=0.6


# Which language should be used? 
# English (:en) & German (:de) are supported, and English is chosen by default.
# If you'd like to use another language, you can find templates in #{RAILS_ROOT}/lang/ui,
# then add your own language in this directory, and modify this line:
Globalite.language = :en
AUTO_CONF
} unless File.readable?(custom_config_file)

require 'ferret'
require custom_config_file