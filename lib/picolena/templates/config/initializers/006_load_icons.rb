icons_config_file='config/custom/icons_and_filetypes.yml'
FiletypeToIconSymbol={}
YAML.load_file(icons_config_file).each_pair{|icon_name, filetypes|
    icon_symbol=icon_name.to_sym
    filetypes.split(/\s/).each{|filetype|
      FiletypeToIconSymbol[filetype.downcase]=icon_symbol
  }
}
