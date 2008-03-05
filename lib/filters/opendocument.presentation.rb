# Open Document Presentation to text conversion:
# http://wiki.opengarden.org/Deki_Wiki/Community_Contributions/Extended_Search
require 'zip/zip'
PlainText.extract {
  from :odp
  as 'application/vnd.oasis.opendocument.presentation'
  aka "Open Document Format for presentation"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.read("content.xml").split(/</).grep(/^text:(p|span)/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Picolena can it find me maybe!', :from => 'ubuntu_theme.odp'
}