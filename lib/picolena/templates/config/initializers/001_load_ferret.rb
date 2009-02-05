require 'ferret'
module Ferret
  module Analysis
   # Used for alias_path queries
   class LetterAnalyzerWithStopFilter
     def initialize(stop_words = FULL_ENGLISH_STOP_WORDS, lower = true)
      @lower = lower
      @stop_words = stop_words
     end

    def token_stream(field, str)
      ts = LetterTokenizer.new(str, @lower)
      StopFilter.new(ts, @stop_words)
    end
   end
  end
end
