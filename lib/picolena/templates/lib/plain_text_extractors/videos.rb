# Basic support for different videos
# It only has been tested with .avi so far

PlainTextExtractor.new {
  every :avi, :mpg, :mpeg, :mov, :wmv
  as "video/*"
  aka "some video"

  extract_thumbnail_with           'ffmpegthumbnailer -s WIDTH -i SOURCE -o THUMBNAIL'

  extract_content_with             'exiftool SOURCE'
  which_should_for_example_extract '(1.96s OR (1.96 s)) AND 320x200 AND Duration AND Image Size', :from => 'badminton.avi'
}
