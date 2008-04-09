custom_localization_yml=File.join(RAILS_ROOT,'lang/ui/custom_localization.yml')

YAML.load_file(custom_localization_yml).each{|key_name, translation|
  Globalite.localizations[key_name.to_sym]=translation
}