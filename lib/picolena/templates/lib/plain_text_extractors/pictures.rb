PlainTextExtractor.new {
  every :bmp, :crw, :eps, :gif, :jpeg, :jpg, :nef, :png, :raw, :tif, :tiff
  as "image/*"
  aka "some picture"

  extract_thumbnail_with           'convert -quality QUALITY -thumbnail WIDTHxHEIGHT SOURCE THUMBNAIL'

  extract_content_with             'exiftool SOURCE'
  which_should_for_example_extract 'Eric Duminil Nikon D90'                      , :from => 'crow.jpg'
  or_extract                       '64x64 BMP'                                   , :from => 'gnu.bmp'
  or_extract                       'application/postscript 258x43'               , :from => 'diceface.eps'
  or_extract                       'Panasonic DMC-FZ8 320x240'                   , :from => 'glass.png'
  or_extract                       '(Panasonic DMC-FZ8 Focal Length In 35mm Format) AND ((432 mm) OR 432mm)', :from => 'cygnus.jpeg'
  or_extract                       '"1990 bytes" 24x24 LZW'                      , :from => 'warning.tiff'
  or_extract                       '"1978 bytes" 24x24 LZW'                      , :from => 'caution.tif'
  or_extract                       'GIF 110x140'                                 , :from => 'rails_logo_remix.gif'
  # Raw pictures (.nef, .crw, .raw) would also need to be tested, but their size doesn't make it worth including
  # corresponding files in the repository. Specs will therefore stay with "Not Yet Implemented" status.
}
