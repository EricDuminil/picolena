= Picolena

* http://picolena.devjavu.com
* http://github.com/EricDuminil/picolena/

== DESCRIPTION:

Picolena is a lightweight ferret-powered documents search engine written in Ruby on rails:

   1. Just let Ferret index any directory you want.
   2. Enter queries on your browser to get corresponding documents in a few milliseconds.

== FEATURES:

Picolena has many advantages:

   * it can index .pdf, .doc, .docx, .odt, .xls, .ods, .ppt, .pptx, .odp, .rtf, .html and plain text files will full text search, and offers a very easy way to add new extractors to index other filetype.
   * it is free as in free beer and as in free speech
   * thanks to Ferret, it is very fast
   * it keeps your data private. By default, only the computer on which it is installed can get access to the search engine. Other IP addresses can then be added to a white list.
   * it does not phone home. This claim is somewhat easier to verify on your server, with just a few lines of codes added, than on a Don't be evil black-box server.
   * it can be used to index any ftp, smb, ssh, webdav or local directory.
   * its user interface is available in English, German, Spanish and French.

== DESCRIPTION:

The 'picolena' command creates a new documents search engine, indexing directories specified as parameters.
A default structure will be created in 'picolena' directory.
Since picolena is Rails-based, you can launch the search-engine
web-server just like you would with any Rails application.

== EXAMPLE:
    picolena ~/shared_documents /media/literature
    cd picolena
    ruby script/server

This would create the picolena file structure, index every file inside ~/shared_documents and /media/literature, and launch a web-server available at http://localhost:3000

== REQUIREMENTS:

* packages : antiword catppt exiftool grep html2text iconv pdftotext sed unrtf xls2csv
* gems     : rails ferret paginator haml rubyzip rubigen rspec rspec-rails

== INSTALL:

* sudo gem install picolena

== LICENSE:

Copyright (c) 2009 Eric Duminil

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
