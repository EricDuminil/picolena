module Picolena
  #Loading directories to be indexed
  indexed_dir_config_file='config/custom/indexed_directories.yml'
  IndexedDirectories={}
  yaml_content=YAML.load_file(indexed_dir_config_file)
  yaml_content[RAILS_ENV].each_pair{|abs_or_rel_path, alias_path|
    IndexedDirectories[Pathname(abs_or_rel_path).realpath.to_s]=alias_path
  }
 
  # Create directories that will be used by the Indexer
  IndexSavePath=File.join(IndexesSavePath,ENV["RAILS_ENV"] || "development")
  FileUtils.mkpath IndexSavePath
  MetaIndexPath= File.join(IndexSavePath,'meta')
  FileUtils.mkpath MetaIndexPath

  # Creates a regular expression called ToIgnore
  # which describes files that should not be indexed
  #
  #   ignore:
  #     Thumbs.db
  #     *.bak
  #
  # => /^(Thumbs\.db)|(.*\.bak)$/i
  #
  files_to_ignore=yaml_content['ignore']
  if files_to_ignore then
    ToIgnore=Regexp.new(
      '^'<<files_to_ignore.split(/\s/).map{|filename|
        '('<<Regexp.escape(filename).gsub('\\*','.*')<<')'
      }.join('|')<<'$', Regexp::IGNORECASE)
  else
    # ToIgnore should not be empty, it would match every filename!
    # So Thumbs.db files are ignored by default.
    ToIgnore=/^Thumbs\.db$/
  end
end
