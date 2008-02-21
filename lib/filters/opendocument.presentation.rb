# Open Document to text conversion:
#   Program: odt2txt
#   Version tested: 0.3
#   Home page: http://www.freewisdom.org/projects/python-markdown/odt2txt.php

PlainText.extract {
  from :odp
  as 'application/vnd.oasis.opendocument.presentation'
  aka "Open Document Format for presentation"
  with {|source,destination|
        %x{TEMPDIR=`mktemp -d`
        unzip -oq "#{source}" -d $TEMPDIR   # Extract the file
        tr "<" "\012" < $TEMPDIR/content.xml | egrep '^text:p|text:span' | cut '-d>' -f2, | uniq > "#{destination}"
        rm -r $TEMPDIR}
  }
  which_requires 'unzip', 'tr', 'egrep', 'cut', 'uniq'
  which_should_for_example_extract 'Picolena can it find me\?\?\? maybe!', :from => 'ubuntu_theme.odp'
}