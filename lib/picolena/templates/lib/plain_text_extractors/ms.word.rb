#Word 97-2003

PlainTextExtractor.new {
  every :doc, :dot
  as "application/msword"
  aka "Microsoft Office Word document"
  extract_content_with "antiword SOURCE" => :on_linux_and_mac_os,
                       "some other command" => :on_windows
  which_should_for_example_extract 'district heating', :from => 'Types of malfunction in DH substations.doc'
  or_extract 'Basic Word template for Picolena specs', :from => 'office2003-word-template.dot'
}

#Word 2007

require 'zip/zip'
PlainTextExtractor.new {
  every :docx, :dotx
  as 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  aka "Microsoft Office 2007 Word document"
  extract_content_with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.read("word/document.xml").split(/</).grep(/^w:t/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Can this office 2007 document be indexed\?', :from => 'office2007-word.docx'
  or_extract 'Basic Word 2007 template for Picolena specs', :from => 'office2007-word-template.dotx'
}

## Microsoft Word to text conversion:
##   Program: antiword
##   Version tested: 0.37
##   Installation: Ubuntu antiword package
##   Home page: http://www.winfield.demon.nl/

## MS OOXML word to text conversion:
## Ruby code written by Eric DUMINIL
