PlainTextExtractor.new {
  every :html, :htm
  as "text/html"
  aka "HyperText Markup Language document"
  with {|source|
    encoding=File.encoding(source)
    if encoding.empty? or encoding.gsub(/[^\w]/,'').downcase=="utf8" then
      %x{html2text -nobs "#{source}"}
    else
      %x{html2text -nobs "#{source}" | iconv -f #{encoding} -t utf8}
    end
  }
  which_requires 'html2text', 'iconv'
  which_should_for_example_extract 'zentrum für angewandte forschung an fachhochschulen nachhaltige energietechnik Baden-Württemberg', :from => 'zafh.net.html'
  or_extract 'Málaga', :from => '7.html'
  or_extract 'le monde', :from => 'lemonde.htm'
}
