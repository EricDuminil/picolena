# MS OOXML word to text conversion

PlainText.extract {
  from :pptx
  as 'application/vnd.openxmlformats-officedocument.presentationml.presentation' #could that mime BE any longer?
  aka "Microsoft Office 2007 Powerpoint document"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.entries.select{|l|
        l.name=~/^ppt\/slides\/slide\d+.xml/
      }.collect{|entry|
        zipfile.read(entry).split(/</).grep(/^a:t/).collect{|l|
            l.sub(/^[^>]+>/,'')
          }
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Welcome to Picolena (one more time!)', :from => 'office2007-powerpoint.pptx'
}