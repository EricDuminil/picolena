module Picolena
  IndexingConfiguration={}
  YAML.load_file('config/custom/indexing_performance.yml').each_pair{|param, value|
    IndexingConfiguration[param.to_sym]= value=~/^[\d_]+$/ ? value.to_i : value
  }
end