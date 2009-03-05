desc 'Ferret index maintenance tasks'

namespace :log do
  desc 'Parse log files for queries'
  task :queries do
    show_action_with_query=/Processing DocumentsController#show \(for ([\d\.]+) at ([\d\- :]+)\) \[GET\]\s+Parameters: \{"id"=>"(.*?)"\}/
    log_file='log/'<<(ENV["RAILS_ENV"]||"production")<<'.log'
    File.read(log_file).scan(show_action_with_query).each{|ip,time, query|
      #2009-03-05 15:13:28 (193.196.142.40) : trinkle
      puts "#{time} (#{ip.center(15)}) : #{query}"
    }
  end
end
