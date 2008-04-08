require 'rake/rdoctask'

Rake::Task[:docs].abandon

desc "Generate API documentation"
task :docs => :appdoc

desc "Generate documentation for the application"
rd = Rake::RDocTask.new("appdoc") do |rdoc|
  #FIXME: Find out why 'doc' indexes every file, while 'doc/.' indexes only those specified below
  rdoc.rdoc_dir = 'doc/.'
  rdoc.title    = "Picolena Documentation"
  rdoc.options << '--line-numbers'
  rdoc.options << '--inline-source'
  rdoc.options << '--charset=utf-8'
  rdoc.rdoc_files.include('README.txt')
  rdoc.rdoc_files.include('History.txt')
  rdoc.rdoc_files.include('MIT-LICENSE')
  rdoc.rdoc_files.include('lib/picolena/templates/app/**/*.rb')
  rdoc.rdoc_files.include('lib/picolena/templates/lib/**/*.rb')
end