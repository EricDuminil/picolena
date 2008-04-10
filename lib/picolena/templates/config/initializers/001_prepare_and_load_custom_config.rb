### You should not modify this file if you'd like to customize your search engine.
### Please modify config/custom/picolena.rb instead.
### A template config/custom/picolena.rb will be created the first time you launch your web server.


custom_config_file = File.join(RAILS_ROOT, 'config/custom/picolena.rb')

File.open(custom_config_file,'w'){|custom|
  custom.puts <<-DEFAULT_CONF
### This file has been automatically generated the first time you launched your web server.
### You should add custom requirements here, they will be loaded everytime you restart the web server.


# Specify indexes path.
# Storage should be sufficient in order to store all indexed data.
IndexesSavePath=File.join(RAILS_ROOT, 'tmp/ferret_indexes/')


# Which language should be used?
# English (:en), German (:de), French (:fr) and Spanish (:es) are currently supported
# English is chosen by default.
# If you'd like to use another language, you can find templates in #{RAILS_ROOT}/lang/ui,
# then add your own language in this directory, and modify this line:
Globalite.language = :en


# Specify which locale should be used by Ferret
Ferret.locale = "en_US.UTF-8"

# Results per page
ResultsPerPage = 10

# Length of "probably unique id" 's
# Those id's are used to characterize every document, thus allowing tiny URLs in Controllers
#  HashLength = 10
#  Document.new("whatever.pdf").probably_unique_id => "bbuxhynait"
#  HashLength = 20
#  Document.new("whatever.pdf").probably_unique_id => "jfzjkyfkfkbbuxhynait"
# The more documents you have, the bigger HashLength should be in order to avoid collisions.
# It would not be wise (and specs won't pass) to specify HashLength smaller than 10.
HashLength = 10

# Specify the default Levenshtein distance when using FuzzyQuery
# see http://ferret.davebalmain.com/api/classes/Ferret/QueryParser.html for more information.
Ferret::Search::FuzzyQuery.default_min_similarity=0.6
DEFAULT_CONF
} unless File.readable?(custom_config_file)

require 'ferret'
require custom_config_file
