# Open Document Presentation to text conversion:
# http://wiki.opengarden.org/Deki_Wiki/Community_Contributions/Extended_Search

PlainText.extract {
  from :odp
  as 'application/vnd.oasis.opendocument.presentation'
  aka "Open Document Format for presentation"
  #TODO: Should be written in Ruby!
  with {|source|
        %x{TEMPDIR=`mktemp -d`
        unzip -oq "#{source}" -d $TEMPDIR   # Extract the file
        tr "<" "\012" < $TEMPDIR/content.xml | egrep '^text:p|text:span' | cut '-d>' -f2, | uniq}
  }
  which_requires 'mktemp', 'unzip', 'tr', 'egrep', 'cut', 'uniq'
  which_should_for_example_extract 'Picolena can it find me\?\?\? maybe!', :from => 'ubuntu_theme.odp'
}