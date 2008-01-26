require 'ferret'

# Customized Ferret Analyser, with stems and German & English stem words

FULL_ENGLISH_AND_GERMAN_STOP_WORDS=Ferret::Analysis::FULL_ENGLISH_STOP_WORDS+Ferret::Analysis::FULL_GERMAN_STOP_WORDS

class CustomAnalyzer < Ferret::Analysis::Analyzer
  include Ferret::Analysis
  def initialize
    @lower = true
    @stop_words = FULL_ENGLISH_AND_GERMAN_STOP_WORDS
  end
  
  def token_stream(field, str)
    #TODO: Report bug. 
    #<Ferret::Analysis::HyphenFilter:0xb6f33958>
    #lib/ff.rb:56: [BUG] Segmentation fault
    #ruby 1.8.6 (2007-06-07) [i486-linux]
    #
    #Aborted (core dumped)
    #rake aborted!
    #When using this:
    #ts = StandardTokenizer.new(str)
    #ts = LowerCaseFilter.new(ts) if @lower
    #ts = StopFilter.new(ts, @stop_words)
    #ts = HyphenFilter.new(ts)
    #ts = StemFilter.new(ts,"en", "UTF-8")
    #but not:
    #ts = StemFilter.new(ts,"en")
    StemFilter.new(HyphenFilter.new(StopFilter.new(LowerCaseFilter.new(StandardTokenizer.new(str)), @stop_words)))
  end
end
