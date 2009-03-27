PlainTextExtractor.new {
  every :psd
  as "image/adobe.photoshop"
  aka "Adobe Photoshop Format"

  #NOTE: PSD gets its own Extractor since convert method is different from one-layer pictures
  #      and needs -flatten option
  extract_thumbnail_with           'convert SOURCE -flatten -thumbnail WIDTHxHEIGHT -quality QUALITY THUMBNAIL'

  extract_content_with             'exiftool SOURCE'
  which_should_for_example_extract '"Adobe Photoshop CS2 Windows" 584x150', :from => 'picolena.psd'
}
