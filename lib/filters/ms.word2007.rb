# MS OOXML word to text conversion

require 'zip/zip'
PlainText.extract {
  from :docx, :dotx
  as 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  aka "Microsoft Office 2007 Word document"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.read("word/document.xml").split(/</).grep(/^w:t/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Can this office 2007 document be indexed\?', :from => 'office2007-word.docx'
  or_extract 'Basic Word 2007 template for Picolena specs', :from => 'office2007-word-template.dotx'
}