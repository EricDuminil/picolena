class Query
  class << self
    # Returns a Ferret::Query from a raw String query.
    def extract_from(raw_query)
      parser.parse(convert_to_english(raw_query))
    end
    
    # Returns terms related to content. Useful for cache highlighting
    def content_terms(raw_query)
      Query.extract_from(raw_query).terms(Indexer.index.searcher).select{|term| term.field==:cache_content}.collect{|term| term.text}.uniq
    end

    private

    # Converts query keywords to english so they can be parsed by Ferret.
    def convert_to_english(raw_query)
      to_en={
       /\b#{:AND.l}\b/=>'AND',
       /\b#{:OR.l}\b/=>'OR',
       /\b#{:NOT.l}\b/=>'NOT',
       /(#{:filename.l}):/=>'filename:',
       /(#{:filetype.l}):/=>'filetype:',
       /#{:content.l}:/ => 'cache_content:',
       /(#{:modified.l}):/ => 'cache_mtime:',
       /(#{:language.l}):/ => 'language:',
       /\b#{:LIKE.l}\s+(\S+)/=>'\1~'
      }
      to_en.inject(raw_query){|mem,non_english_to_english_keyword|
        mem.gsub(*non_english_to_english_keyword)
      }
    end

    # Instantiates a QueryParser once, and keeps it in cache.
    def parser
      @@parser ||= Ferret::QueryParser.new(:fields => [:cache_content, :filename, :basename, :alias_path, :filetype, :cache_mtime], :or_default => false, :analyzer=>Picolena::Analyzer)
    end
  end
end
