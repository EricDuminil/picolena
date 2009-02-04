PlainTextExtractor.new {
  every :bmp, :crw, :eps, :gif, :jpeg, :jpg, :nef, :png, :raw, :tif, :tiff
  as "image/*"
  aka "some picture"

  extract_thumbnail_with           'convert -quality 50 -thumbnail 80x80 SOURCE THUMBNAIL'

  extract_content_with             'exiftool SOURCE'
  which_should_for_example_extract 'Eric Duminil Nikon D90'                      , :from => 'crow.jpg'
  or_extract                       '64x64 BMP'                                   , :from => 'gnu.bmp'
  or_extract                       'application/postscript 258x43'               , :from => 'diceface.eps'
  or_extract                       'Panasonic DMC-FZ8 320x240'                   , :from => 'glass.png'
  or_extract                       'Panasonic DMC-FZ8 "35mm equivalent: 432.0mm"', :from => 'cygnus.jpeg'
}
