class IndexerLogger<Logger
  def initialize
    super($stdout)
    #FIXME: Should be defined in config/environments/*.rb
    levels={
      "development"=>Logger::DEBUG,
      "production" =>Logger::INFO,
      "test"       =>Logger::WARN    
    }
    @level=levels[RAILS_ENV]
    @found_languages={}
    @supported_filetypes={}
    @unsupported_filetypes={}
  end

  def start_indexing
    @start_time=Time.now
    debug "Indexing every directory"
  end

  def add_document(document)
    debug ["Added : #{document[:complete_path]}",document[:language] && " ("<<document[:language]<<")"].join
    @found_languages.add(document[:language]) if document[:language]
    @supported_filetypes.add(document[:filetype])
  end

  def reject_document(document, error)
    @unsupported_filetypes.add(document[:filetype])
    debug "Added without content (#{error.message}) : #{document[:complete_path]}"
  end
  
  def show_report
    describe :found_languages, :supported_filetypes, :unsupported_filetypes
    info "Time needed              : #{Time.now-@start_time} s."
  end
  
  private

  def describe(*instance_variable_names)
    instance_variable_names.each{|var_name|
      hash=instance_variable_get("@#{var_name}")
      info var_name.to_s.humanize.ljust(25)<<": "<<hash.reject{|k,v| k.blank?}.sort_by{|k,v| v[:size]}.reverse.collect{|k,v| "#{k.downcase} (#{v[:size]})"}.join(", ") unless hash.empty?
    }
  end
end
