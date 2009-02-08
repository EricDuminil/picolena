PlainTextExtractor.new {
  every :zip
  as "archive/zip"
  aka "ZIP Archive"

  # NOTE: With RubyZip or just a tmp dir from unzip?
  extract_content_with {|source|
    begin
      temp_dir=File.join(Dir::tmpdir, 'picolena_zip_temp', source.base26_hash)
      FileUtils.mkpath temp_dir
      Zip::ZipFile.open(source){|zipfile|
        zipfile.select{|entry| entry.file?}.map{|entry|
          tmp_file=File.join(temp_dir, [entry.name.base26_hash, File.extname(entry.name)].compact.join('.'))
          entry.extract(tmp_file)
          content=PlainTextExtractor.extract_content_from(tmp_file) rescue "---"
          ["## "<<entry.name.gsub('/', '>'), content]
        }
      }.compact.join("\n")
    ensure
      FileUtils.remove_entry_secure(temp_dir)
      FileUtils.rmdir(File.join(Dir::tmpdir, 'picolena_zip_temp')) rescue "not empty"
    end
  }

  which_should_for_example_extract 'some_test_files some_dir dumb.rb', :from => 'some_test_files.zip'
  or_extract                       'puts 2+2',                         :from => 'some_test_files.zip'
  # Now *that* is some cool spec!
  or_extract                       'This sentence is hidden in the EXIF metadata of a .jpg file archived in a .zip file archived in a .zip file!',
                                                                       :from => 'some_test_files.zip'
}
