# Open Document to text conversion:
#   Program: odt2txt
#   Version tested: 0.3
#   Home page: http://www.freewisdom.org/projects/python-markdown/odt2txt.php

Filter.which {
  convert [:doc, :dot]
  as 'application/vnd.oasis.opendocument.text'
  aka "Open Document Format for text"
  with "odt2txt SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
}

#  def odt_to_text(src, dst)
#    %x{odt2txt \"#{src}\" > \"#{dst}\" 2>/dev/null}
#    raise 'missing odt2txt.py(1) command' if $?.exitstatus == 127
#    raise "failed to convert Open Document text file: #{src}" unless $?.exitstatus == 0
#  end