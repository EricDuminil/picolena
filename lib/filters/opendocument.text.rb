# Open Document to text conversion:
#   Program: odt2txt
#   Version tested: 0.3
#   Home page: http://www.freewisdom.org/projects/python-markdown/odt2txt.php

PlainText.extract {
  from :odt
  as 'application/vnd.oasis.opendocument.text'
  aka "Open Document Format for text"
  with "odt2txt SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
}