PlainTextExtractor.new {
  every :psd
  as "image/adobe.photoshop"
  aka "Adobe Photoshop Format"
  extract_content_with 'exiftool SOURCE'
  #NOTE: PSD gets its own Extractor since convert method is different from one-layer pictures
  extract_thumbnail_with 'convert SOURCE -flatten -thumbnail 80x80 -quality 50 THUMBNAIL'

  which_should_for_example_extract '"Adobe Photoshop CS2 Windows" 584x150', :from => 'picolena.psd'
}
