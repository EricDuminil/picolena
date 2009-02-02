PlainTextExtractor.new {
  every :bmp, :crw, :eps, :gif, :jpeg, :jpg, :nef, :png, :psd, :raw, :tif, :tiff
  as "image/*"
  aka "some picture"
  with 'exiftool SOURCE'
  which_requires 'exiftool'
  which_should_for_example_extract 'Eric Duminil Nikon D90', :from => 'crow.jpg'
}
