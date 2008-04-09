desc 'Create development picolena structure inside lib/picolena/templates'
task :lets_hack do
  picolena_root=File.join(File.dirname(__FILE__),'..')
  Dir.chdir(picolena_root){
    system("ruby bin/picolena lib/picolena/templates/spec/test_dirs --skip --no-index --no-spec --destination=lib/picolena/templates")
  }
end