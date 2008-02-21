PlainText.extract {
  from :html, :htm
  as "text/html"
  aka "HyperText Markup Language document"
  with {|source,destination|
    encoding=File.encoding(source)
    encoding="iso-8859-15" if encoding.empty?
    %x{html2text -nobs "#{source}" | iconv -f #{encoding} -t utf8 >"#{destination}" 2>/dev/null}
  }
}