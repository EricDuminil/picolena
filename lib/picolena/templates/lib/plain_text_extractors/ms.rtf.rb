# Microsoft Rich Text Format to text conversion:
#   Program: unrtf
#   Version tested: 0.19.2
#   Installation: Ubuntu unrtf package
#   http://www.gnu.org/software/unrtf/unrtf.html

PlainTextExtractor.new {
  every :rtf
  as "application/rtf"
  aka "Microsoft Rich Text Format"
  extract_content_with "unrtf  SOURCE -t text" => :on_linux_and_mac_os,
                       "some other command" => :on_windows

  extract_thumbnail_with {|source, destination|
    wmf_pics_inside_rtf=Dir.glob("#{RAILS_ROOT}/pict*.wmf")
    unless wmf_pics_inside_rtf.empty?
      silently_execute("convert -quality 50 -thumbnail 80x80 #{wmf_pics_inside_rtf.first} #{destination}")
      wmf_pics_inside_rtf.each{|f| FileUtils.rm f}
    end
  }
  which_requires "wmf2eps"

  which_should_for_example_extract 'Resampling when limiting', :from => 'ReadMe.rtf'
}
