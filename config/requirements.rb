require 'fileutils'
include FileUtils

require 'rubygems'
%w[rake newgem rubigen].each do |req_gem|
  begin
    require req_gem
  rescue LoadError
    puts "This Rakefile requires the '#{req_gem}' RubyGem."
    puts "Installation: gem install #{req_gem} -y"
    exit
  end
end

class Rake::Task
  def overwrite(&block)
    @actions.clear
    prerequisites.clear
    enhance(&block)
  end
  def abandon
    prerequisites.clear
    @actions.clear
  end
end

$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))
