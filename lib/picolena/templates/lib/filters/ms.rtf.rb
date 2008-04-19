# Microsoft Rich Text Format to text conversion:
#   Program: unrtf
#   Version tested: 0.19.2
#   Installation: Ubuntu unrtf package
#   http://www.gnu.org/software/unrtf/unrtf.html

Filter.new {
  every :rtf
  as "application/rtf"
  aka "Microsoft Rich Text Format"
  with "unrtf  SOURCE -t text" => :on_linux, "some other command" => :on_windows
  which_should_for_example_extract 'Resampling when limiting', :from => 'ReadMe.rtf'
}