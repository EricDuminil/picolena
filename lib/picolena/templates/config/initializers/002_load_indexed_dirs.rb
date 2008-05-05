module Picolena
  #Loading directories to be indexed
  indexed_dir_config_file='config/custom/indexed_directories.yml'
  IndexedDirectories={}
  YAML.load_file(indexed_dir_config_file)[RAILS_ENV].each_pair{|abs_or_rel_path, alias_path|
    IndexedDirectories[Pathname(abs_or_rel_path).realpath.to_s]=alias_path
  }
  
  IndexSavePath=File.join(IndexesSavePath,ENV["RAILS_ENV"] || "development")
  FileUtils.mkpath IndexSavePath
end
