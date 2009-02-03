# Open Document Presentation to text conversion

require 'zip/zip'
PlainTextExtractor.new {
  every :odp
  as 'application/vnd.oasis.opendocument.presentation'
  aka "Open Document Format for presentation"
  extract_content_with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.read("content.xml").split(/</).grep(/^text:(p|span)/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Picolena can it find me maybe!', :from => 'ubuntu_theme.odp'
}
