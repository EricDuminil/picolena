# Open Document Spreadsheet to text conversion

require 'zip/zip'
Filter.new {
  every :ods
  as 'application/vnd.oasis.opendocument.spreadsheet'
  aka "Open Document Format for spreadsheet"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      zipfile.read("content.xml").split(/</).grep(/^text:(p|span)/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }.join("\n")
    }
  }
  which_should_for_example_extract 'Cessna F-172P G-BIDF, serial number 2045', :from => 'weight_and_balance.ods'
}