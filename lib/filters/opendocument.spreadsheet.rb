# Open Document Spreadsheet to text conversion:
# http://wiki.opengarden.org/Deki_Wiki/Community_Contributions/Extended_Search

PlainText.extract {
  from :ods
  as 'application/vnd.oasis.opendocument.spreadsheet'
  aka "Open Document Format for spreadsheet"
  #Should be written in Ruby!
  with {|source|
        %x{TEMPDIR=`mktemp -d`
        unzip -oq "#{source}" -d $TEMPDIR   # Extract the file
        tr "<" "\012" < $TEMPDIR/content.xml | egrep '^text:p|text:span' | cut '-d>' -f2, | uniq}
  }
  which_requires 'mktemp', 'unzip', 'tr', 'egrep', 'cut', 'uniq'
  which_should_for_example_extract 'Cessna F-172P G-BIDF, serial number 2045', :from => 'weight_and_balance.ods'
}