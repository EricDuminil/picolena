PlainText.extract {
  from :html, :htm
  as "text/html"
  aka "HyperText Markup Language document"
  with {|source|
    encoding=File.encoding(source)
    encoding="iso-8859-15" if encoding.empty?
    %x{html2text -nobs "#{source}" | iconv -f #{encoding} -t utf8}
  }
  which_requires 'html2text', 'iconv'
  which_should_for_example_extract 'zentrum für angewandte forschung an fachhochschulen nachhaltige energietechnik Baden-Württemberg', :from => 'zafh.net.html'
  or_extract 'le monde', :from => 'lemonde.htm'
}