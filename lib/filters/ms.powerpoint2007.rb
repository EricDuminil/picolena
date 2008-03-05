# MS OOXML word to text conversion:
# http://wiki.opengarden.org/Deki_Wiki/Community_Contributions/Extended_Search

PlainText.extract {
  from :pptx
  as 'application/vnd.openxmlformats-officedocument.presentationml.presentation' #could that mime BE any longer?
  aka "Microsoft Office 2007 Powerpoint document"
  #TODO: Should be written in Ruby!
  with {|source|
        %x{TEMPDIR=`mktemp -d`
        unzip -oq "#{source}" -d $TEMPDIR   # Extract the file
        cat $TEMPDIR/ppt/slides/slide*.xml | tr "<" "\012" | grep ^a:t | cut '-d>' -f2, | uniq}
  }
  which_requires 'cat', 'unzip', 'tr', 'grep', 'cut', 'uniq'
  which_should_for_example_extract 'Welcome to Picolena (one more time!)', :from => 'office2007-powerpoint.pptx'
}