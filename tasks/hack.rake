desc 'Create development picolena structure inside lib/picolena/templates'
task :lets_hack => :clean do
  picolena_root=File.join(File.dirname(__FILE__),'..')
  Dir.chdir(picolena_root){
    # Doesn't overwrite any file, Doesn't create any index, Doesn't launch any spec.
    system("ruby bin/picolena lib/picolena/templates/spec/test_dirs/indexed --no-index --no-spec --destination=lib/picolena/templates")
  }
  puts <<-EXPLAIN
  
  You now have a complete picolena installation in:
    #{File.expand_path(File.join(File.dirname(__FILE__),'../lib/picolena/templates'))}
  
  You can now hack and submit patches!
  
  Once done, you can remove those files by typing:
    rake clean
  EXPLAIN
end