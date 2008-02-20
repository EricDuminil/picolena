PlainText.extract {
  from :html, :htm
  as "text/html"
  aka "HyperText Markup Language document"
  with {some_ruby_magic_coming_soon}
}

#  def html_to_text(src, dst)
#    encoding=File.which_encoding_for?(src)
#    encoding="iso-8859-15" if encoding.empty?
#    %x{html2text -nobs SOURCE | iconv -f #{encoding} -t utf8 >DESTINATION 2>/dev/null}
#    raise 'missing html2text(1) command' if $?.exitstatus == 127
#    raise "failed to convert HTML file: #{src}" unless $?.exitstatus == 0
#  end