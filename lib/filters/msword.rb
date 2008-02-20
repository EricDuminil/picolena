# Microsoft Word to text conversion:
#   Program: antiword
#   Version tested: 0.37
#   Installation: Ubuntu antiword package
#   Home page: http://www.winfield.demon.nl/

PlainText.filter {
  convert :doc, :dot
  as "application/msword"
  aka "Microsoft Office Word document"
  with "antiword SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
}