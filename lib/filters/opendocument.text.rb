# Open Document Presentation to text conversion:
# http://wiki.opengarden.org/Deki_Wiki/Community_Contributions/Extended_Search

PlainText.extract {
  from :odt
  as 'application/vnd.oasis.opendocument.text'
  aka "Open Document Format for text"
  with "odt2txt SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'OpenOffice.org', :from => 'basic.odt'
}