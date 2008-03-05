# Open Document to text conversion

PlainText.extract {
  from :odt
  as 'application/vnd.oasis.opendocument.text'
  aka "Open Document Format for text"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.read("content.xml").split(/</).grep(/^text:(p|span)/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }.join("\n")
    }
  }
  which_should_for_example_extract 'written with OpenOffice.org', :from => 'basic.odt'
}