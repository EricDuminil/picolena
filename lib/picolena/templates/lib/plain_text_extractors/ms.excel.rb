#Excel 97-2003

PlainTextExtractor.new {
  every :xls
  as "application/excel"
  aka "Microsoft Office Excel document"
  with "xls2csv SOURCE 2>/dev/null | grep -i [a-z] | sed -e 's/\"//g' -e 's/,*$//' -e 's/,/ /g'" => :on_linux_and_mac_os,
       "some other command" => :on_windows
  which_should_for_example_extract 'Some text (should be indexed!)', :from => 'table.xls'
}

#Excel 2007

require 'zip/zip'
PlainTextExtractor.new {
  every :xlsx
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

## Microsoft Excel to text conversion:
##   Program: xls2csv
##   Version tested: 0.37
##   Installation: Ubuntu catdoc package
##   Home page: http://www.winfield.demon.nl/

## MS OOXML excel to text conversion:
## Ruby code written by Eric DUMINIL