# Microsoft Word to text conversion:
#   Program: antiword
#   Version tested: 0.37
#   Installation: Ubuntu antiword package
#   Home page: http://www.winfield.demon.nl/

PlainText.extract {
  from :xls
  as "application/excel"
  aka "Microsoft Office Excel document"
  with "xls2csv SOURCE 2>/dev/null | grep -i [a-z] | sed -e 's/\"//g' -e 's/,*$//' -e 's/,/ /g' > DESTINATION" => :on_linux, "some other command" => :on_windows
}