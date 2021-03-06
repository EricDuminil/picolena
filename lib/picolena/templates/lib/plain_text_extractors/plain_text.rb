PlainTextExtractor.new {
  every :txt, :text
  every :tex, :bib, :for, :cpp, :c, :rb, :ins, :vee, :java
  every :ini
  #NOTE: Might be worth parsing subtitles to remove time scale
  every :srt
  #NOTE: Could be interesting to extract thumbnail from vCards
  every :vcf, :vcard 
  every :no_extension

  as "application/plain"
  aka "plain text file"
  extract_content_with {|source|
    if File.plain_text?(source) then
      encoding=File.encoding(source)
      if encoding.empty? then
        File.read(source)
      else
        %x{iconv -f #{encoding} -t utf8  "#{source}" 2>/dev/null}
      end
    end
  }
  # for dependencies spec
  which_requires 'iconv'

  # to check if the extractor is working with basic plain text files
  which_should_for_example_extract 'Hello world!', :from => 'hello.rb'
  or_extract 'text inside!', :from => 'crossed.txt'
  or_extract 'txt inside!', :from => 'crossed.text'
  or_extract 'should index LaTeX too', :from => 'basic.tex'
  or_extract 'public static void main', :from => 'myfirstjavaprog.java'
  or_extract '"void CMatrix::inv()"', :from => 'ccmatrix1.cpp'
  or_extract 'CALL TEST(BOARD,X,Y,POSSIBLE)', :from=>'queens.for'
  or_extract 'This program calculates greatest common divisors', :from=>'gcd.c'
  or_extract 'p 3 square.dat', :from => 'square.ins'
  or_extract 'Do loop (global)', :from => 'xor.vee'
  or_extract 'Bubba Gump Shrimp Co', :from => 'forrest_gump.vcf'
  or_extract 'eric duminil wrong_address@picolena.com', :from => 'rx_dml.vcard'
  or_extract 'John Doe 192.0.2.42', :from => 'config.ini'
  or_extract 'Design of a Carbon Fiber Composite Grid Structure for the GLAST Spacecraft Using a Novel Manufacturing Technique', :from => 'design_of_a_carbon_fiber.bib'
  or_extract 'for the very last time', :from => 'dh_part.srt'

  # to check if other charsets are supported
  or_extract 'püöüökäößß AND ßklüöü', :from => 'utf-8.txt'
  or_extract 'Themenliste für Adsorptionskälte', :from => 'iso-8859-1.txt'
  or_extract 'F€rnwärme', :from => 'iso-8859-15.txt'
  or_extract 'The previous line includes some weird chars. Will this file be indexed\?', :from => 'weird_chars.txt'
  or_extract 'Incidentally this file should get indexed as well', :from => 'README'
  or_extract 'OMG_thIs_Is_A_w3ird_fileN4mE!', :from => "'weird'filename.txt"
}
