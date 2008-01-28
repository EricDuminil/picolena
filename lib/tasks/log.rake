desc 'Ferret index maintenance tasks'

namespace :log do  
  desc 'Parse log files for queries'
  task :queries do
    show_action_regexp=/Processing DocumentsController#show \(for ([\d\.]+) at ([\d\- :]+)\) \[GET\]/
    paramaters_regexp=/"id"=>"(.*?)"/
    one_line_or_the_other=Regexp.union(show_action_regexp,paramaters_regexp)
    log_file='log/'<<(ENV["RAILS_ENV"]||"production")<<'.log'
    File.readlines(log_file).grep(one_line_or_the_other).each{|line|
      case line
        when show_action_regexp
        print "#{$2} (#{$1})"
        when /\{"format"=>"(.*?)", "action"=>"show", "id"=>"(.*?)"/
        puts " : #{$2}.#{$1}"
        when /\{"action"=>"show", "id"=>"(.*?)"/
        puts " : #{$1}"
      end
    }
  end
end