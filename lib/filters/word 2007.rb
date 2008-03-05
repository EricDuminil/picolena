# MS OOXML word to text conversion:
# http://wiki.opengarden.org/Deki_Wiki/Community_Contributions/Extended_Search

PlainText.extract {
  from :docx
  as 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  aka "Microsoft Office 2007 Word document"
  #TODO: Should be written in Ruby!
  with {|source|
        %x{TEMPDIR=`mktemp -d`
        unzip -oq "#{source}" -d $TEMPDIR   # Extract the file
        tr "<" "\012" < $TEMPDIR/word/document.xml | grep ^w:t | cut '-d>' -f2, | uniq}
  }
  which_requires 'mktemp', 'unzip', 'tr', 'grep', 'cut', 'uniq'
  which_should_for_example_extract 'Can this office 2007 document be indexed\?', :from => 'office2007-word.docx'
}