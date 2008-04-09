desc 'Create a temporary picolena structure and launch specs from it'
task :spec do
  require 'pathname'
  picolena_bin=Pathname(File.join(File.dirname(__FILE__),'../bin/picolena')).realpath.to_s
  system("ruby #{picolena_bin} --spec-only")
end