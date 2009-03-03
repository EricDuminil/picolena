class IndexerLogger<Logger
  attr_accessor :documents_number

  def initialize
    super($stdout)
    @level=Picolena::LOGLEVEL
    @found_languages={}
    @supported_filetypes={}
    @unsupported_filetypes={}
    @indexed_so_far = 0
  end

  def start_indexing
    @start_time=Time.now
    debug "Indexing every directory"
  end

  def add_document(document, update=false)
    debug [percentage, '-', update ? "Updated  " : "Added    ", ':', "#{document.complete_path}",document.language && "("<<document.language<<")"].join(' ')
    @found_languages.add(document.language) if document.language
    @supported_filetypes.add(document.filetype)
  end

  def reject_document(document)
    @unsupported_filetypes.add(document.filetype)
    debug "#{percentage} - Added without content (#{document.extract_error}) : #{document.complete_path}"
  end
  
  def show_report
    describe :found_languages, :supported_filetypes, :unsupported_filetypes
    info "Time needed              : #{Time.now-@start_time} s."
  end

  def percentage
    @indexed_so_far+=1
    (@indexed_so_far.to_f/@documents_number*100).to_i.to_s.rjust(3)+"%"
  end
  
  private

  def describe(*instance_variable_names)
    instance_variable_names.each{|var_name|
      hash=instance_variable_get("@#{var_name}")
      info var_name.to_s.humanize.ljust(25)<<": "<<hash.reject{|k,v| k.blank?}.sort_by{|k,v| v[:size]}.reverse.collect{|k,v| "#{k.downcase} (#{v[:size]})"}.join(", ") unless hash.empty?
    }
  end
end
