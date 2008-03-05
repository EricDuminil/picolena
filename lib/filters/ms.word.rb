# Microsoft Word to text conversion:
#   Program: antiword
#   Version tested: 0.37
#   Installation: Ubuntu antiword package
#   Home page: http://www.winfield.demon.nl/

PlainText.extract {
  from :doc, :dot
  as "application/msword"
  aka "Microsoft Office Word document"
  with "antiword SOURCE" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'district heating', :from => 'Types of malfunction in DH substations.doc'
}