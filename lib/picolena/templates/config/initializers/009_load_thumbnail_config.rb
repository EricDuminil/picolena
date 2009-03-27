module Picolena
  module Thumbnail
    thumbnails_params = YAML.load_file('config/custom/thumbnails.yml')
    x       = thumbnails_params['extract_thumbnails']
    Extract = x.nil? ? true : x
    Quality = thumbnails_params['quality'].to_s            || '50'
    Width   = thumbnails_params['width'].to_s              || '80'
    Height  = thumbnails_params['heigth'].to_s             || '80'
  end
end
