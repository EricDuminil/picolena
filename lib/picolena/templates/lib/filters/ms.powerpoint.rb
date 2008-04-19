#Powerpoint 97-2003

Filter.new {
  from :ppt, :pps
  as "application/powerpoint"
  aka "Microsoft Office Powerpoint document"
  with "catppt SOURCE" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'unofficial written by OOo Impress', :from => 'one_page.ppt'
  #FIXME: it seems that catppt cannot open .pps files.
  #or_extract 'a lightweight ferret-powered search engine written in Ruby on rails.', :from => 'picolena.pps'
}

#Powerpoint 2007

require 'zip/zip'
Filter.new {
  from :pptx
  as 'application/vnd.openxmlformats-officedocument.presentationml.presentation' #could that mime BE any longer?
  aka "Microsoft Office 2007 Powerpoint document"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      slides=zipfile.entries.select{|l| l.name=~/^ppt\/slides\/slide\d+.xml/}
      slides.collect{|entry|
        zipfile.read(entry).split(/</).grep(/^a:t/).collect{|l|
            l.sub(/^[^>]+>/,'')
          }
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Welcome to Picolena (one more time!)', :from => 'office2007-powerpoint.pptx'
}

## Microsoft Powerpoint to text conversion:
##   Program: catppt
##   Version tested: Catdoc Version 0.94.2
##   Installation: Ubuntu catdoc package
##   Home page: http://www.wagner.pp.ru/~vitus/software/catdoc/

## MS OOXML powerpoint to text conversion:
## Ruby code written by Eric DUMINIL