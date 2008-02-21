PlainText.extract {
  from :txt, :text, :tex, :for, :cpp, :c, :rb, :ins, :vee, :java
  as "application/plain"
  aka "Plain text file"
  with {|source,destination|
    encoding=File.encoding(source)
    if encoding.empty? then
       FileUtils.cp source, destination
    else
       %x{iconv -f #{encoding} -t utf8  "#{source}" > "#{destination}" 2>/dev/null}
    end
  }
  # for dependencies spec
  which_requires 'iconv'
  
  # to check if filter is working
  which_should_for_example_extract 'Hello world!', :from => 'hello.rb'
  or_extract 'text inside!', :from => 'crossed.txt'
  or_extract 'txt inside!', :from => 'crossed.text'
  or_extract 'should index LaTeX too', :from => 'basic.tex'
}