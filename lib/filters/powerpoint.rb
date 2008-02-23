# Microsoft Powerpoint to text conversion:
#   Program: catppt
#   Version tested: Catdoc Version 0.94.2
#   Installation: Ubuntu package
#   Home page: http://www.wagner.pp.ru/~vitus/software/catdoc/

PlainText.extract {
  from :ppt, :pps
  as "application/powerpoint"
  aka "Microsoft Office Powerpoint document"
  with "catppt SOURCE" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'unofficial written by OOo Impress', :from => 'one_page.ppt'
}