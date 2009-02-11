# Basic support for different videos
# It only has been tested with .avi so far

PlainTextExtractor.new {
  every :avi, :mpg, :mpeg, :mov, :wmv
  as "video/*"
  aka "some video"

  extract_thumbnail_with           'ffmpegthumbnailer -i SOURCE -o THUMBNAIL'

  extract_content_with             'exiftool SOURCE'
  which_should_for_example_extract 'Image Size 320x200 Duration 1.96s', :from => 'badminton.avi'
}
