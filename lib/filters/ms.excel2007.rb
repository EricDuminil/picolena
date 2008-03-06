# MS OOXML excel to text conversion

require 'zip/zip'
PlainText.extract {
  from :xlsx
  as 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  aka "Microsoft Office 2007 Excel spreadsheet"
  with {|source|
    Zip::ZipFile.open(source){|zipfile|
      text_cells=zipfile.read("xl/sharedStrings.xml").split(/</).grep(/^t/).collect{|l|
        l.sub(/^[^>]+>/,'')
      }
      
      sheet_names=zipfile.read("xl/workbook.xml").split(/</).grep(/^sheet /).collect{|l|
        l.scan(/name="([^"]*)"/)
      }
      (sheet_names+text_cells).join("\n")
    }
  }
  which_should_for_example_extract '<- this result should not be 100000!', :from => 'office2007-excel.xlsx'
  or_extract 'Sheet name should be indexed!!!', :from => 'office2007-excel.xlsx'
}