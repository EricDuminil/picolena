custom_localization_yml=File.join(RAILS_ROOT,'lang/ui/custom_localization.yml')

YAML.load_file(custom_localization_yml).each{|key_name, custom_translation|
  Globalite.localizations[key_name.to_sym]=custom_translation unless custom_translation.blank?
}