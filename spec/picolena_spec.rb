require 'fileutils'
require 'tempfile'
require 'pathname'

picolena_bin=Pathname(File.join(File.dirname(__FILE__),'../bin/picolena')).realpath.to_s
tmp_test_dir=File.join(Dir::tmpdir,"picolena_test_#{Time.now.to_i}")

FileUtils.mkpath tmp_test_dir

begin
  Dir.chdir(tmp_test_dir){
    system("ruby #{picolena_bin} --spec-only")
  }
ensure
 FileUtils.remove_entry_secure tmp_test_dir
end
