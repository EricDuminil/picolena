# PDF to text conversion:
#   Program: pdftotext
#   Version tested: 3.02
#   Installation: Ubuntu  xpdf-utils package
#   Home page: http://www.foolabs.com/xpdf/

PlainTextExtractor.new {
  every :pdf
  as "application/pdf"
  aka "Adobe Portable Document Format"
  with "pdftotext -enc UTF-8 SOURCE -" => :on_linux_and_mac_os,
       "some other command" => :on_windows
  which_should_for_example_extract 'in a pdf file', :from => 'basic.pdf'
}
