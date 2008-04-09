desc 'Create development picolena structure inside lib/picolena/templates'
task :lets_hack do
  require 'pathname'
  picolena_bin=Pathname(File.join(File.dirname(__FILE__),'../bin/picolena')).realpath.to_s
  lib_picolena_templates=Pathname(File.join(File.dirname(__FILE__),'../lib/picolena/templates')).realpath.to_s
  test_dirs=Pathname(File.join(File.dirname(__FILE__),'../lib/picolena/templates/spec/test_dirs')).realpath.to_s
  system("ruby #{picolena_bin} #{test_dirs} --skip --no-index --no-spec --destination=\"#{lib_picolena_templates}\"")
end