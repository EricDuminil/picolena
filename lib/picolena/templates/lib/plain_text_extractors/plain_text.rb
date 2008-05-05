PlainTextExtractor.new {
  every :txt, :text, :tex, :for, :cpp, :c, :rb, :ins, :vee, :java, :no_extension
  as "application/plain"
  aka "plain text file"
  with {|source|
    raise "binary file #{source}" unless File.plain_text?(source)
    encoding=File.encoding(source)
    if encoding.empty? then
      File.read(source)
    else
      %x{iconv -f #{encoding} -t utf8  "#{source}" 2>/dev/null}
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

  # to check if other charsets are supported
  or_extract 'püöüökäößß AND ßklüöü', :from => 'utf-8.txt'
  or_extract 'Themenliste für Adsorptionskälte', :from => 'iso-8859-1.txt'
  or_extract 'F€rnwärme', :from => 'iso-8859-15.txt'
  or_extract 'The previous line includes some weird chars. Will this file be indexed\?', :from => 'weird_chars.txt'
  or_extract 'Incidentally this file should get indexed as well', :from => 'README'
  or_extract 'OMG_thIs_Is_A_w3ird_fileN4mE!', :from => "'weird'filename.txt"
}
