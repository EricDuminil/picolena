# Microsoft Word to text conversion:
#   Program: antiword
#   Version tested: 0.37
#   Installation: Ubuntu antiword package
#   Home page: http://www.winfield.demon.nl/

Filter.which {
  convert [:doc, :dot]
  as "application/msword"
  aka "Microsoft Office Word document"
  with "antiword SOURCE > DESTINATION 2>/dev/null" => :on_linux, "some other command" => :on_windows
}

#  def msword_to_text(src, dst)
#    %x{antiword \"#{src}\" > \"#{dst}\" 2>/dev/null}
#    raise 'missing antiword(1) command' if $?.exitstatus == 127
#    raise "failed to convert Word file: #{src}" unless $?.exitstatus == 0
#  end