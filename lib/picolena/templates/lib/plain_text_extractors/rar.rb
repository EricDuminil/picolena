PlainTextExtractor.new {
  every :rar
  as "archive/rar"
  aka "RAR Archive"

  # If a non-free version of unrar is available, uses it
  # because unrar-nonfree supports more archives than  unrar-free
  if "unrar".installed? then
   extract_content_from_archive_with "unrar x SOURCE TEMPDIR"
  else
   # falls back to unrar-free otherwise
   extract_content_from_archive_with "unrar-free --extract SOURCE TEMPDIR"
  end

  which_should_for_example_extract 'IAE2ORREucIRPx+XgpYcYoO8Twz1TN5/LezRbdwWonlAqpDanBTR+McCehXpk7Pz',
                                                                              :from => 'dumb_file.rar'
  or_extract                       '"(Same file, but inside one directory)"', :from => 'dumb_file.rar'
}
