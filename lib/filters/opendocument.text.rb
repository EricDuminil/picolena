# Open Document to text conversion:
#   Program: odt2txt
#   Version tested: 0.3
#   Home page: http://www.freewisdom.org/projects/python-markdown/odt2txt.php

PlainText.extract {
  from :odt
  as 'application/vnd.oasis.opendocument.text'
  aka "Open Document Format for text"
  with "odt2txt SOURCE" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'OpenOffice.org', :from => 'basic.odt'
}