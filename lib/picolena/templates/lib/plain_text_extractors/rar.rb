PlainTextExtractor.new {
  every :rar
  as "archive/rar"
  aka "RAR Archive"

  extract_content_from_archive_with "unrar x SOURCE TEMPDIR"

  which_should_for_example_extract 'IAE2ORREucIRPx+XgpYcYoO8Twz1TN5/LezRbdwWonlAqpDanBTR+McCehXpk7Pz',
                                                                              :from => 'dumb_file.rar'
  or_extract                       '"(Same file, but inside one directory)"', :from => 'dumb_file.rar'
}
