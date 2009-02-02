Rake::Task[:ridocs].overwrite do
  sh %q{rdoc --ri --exclude lib/picolena/templates/vendor -o ri lib/picolena/templates}
end
