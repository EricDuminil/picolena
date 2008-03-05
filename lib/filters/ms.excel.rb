# Microsoft Word to text conversion:
#   Program: antiword
#   Version tested: 0.37
#   Installation: Ubuntu antiword package
#   Home page: http://www.winfield.demon.nl/

PlainText.extract {
  from :xls
  as "application/excel"
  aka "Microsoft Office Excel document"
  with "xls2csv SOURCE | grep -i [a-z] | sed -e 's/\"//g' -e 's/,*$//' -e 's/,/ /g'" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'Some text (should be indexed!)', :from => 'table.xls'
}