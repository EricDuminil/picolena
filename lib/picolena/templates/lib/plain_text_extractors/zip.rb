PlainTextExtractor.new {
  every :zip
  as "archive/zip"
  aka "ZIP Archive"

  # TODO: Transpose this structure to support .tgz, .rar, .deb, 7z, ar, .cab, .ace, .lzma, .bz2
  # NOTE: What to do when the archive is too big?

  extract_content_from_archive_with "unzip SOURCE -d TEMPDIR"

  which_should_for_example_extract 'some_test_files some_dir dumb.rb', :from => 'some_test_files.zip'
  or_extract                       'puts 2+2',                         :from => 'some_test_files.zip'
  # Now *that* is some cool spec!
  # It relies on .jpg and .rar Extractors
  or_extract                       '"This sentence is hidden in the EXIF metadata of a .jpg file archived in a .rar file archived in a .zip file!"',
                                                                       :from => 'some_test_files.zip'
}
