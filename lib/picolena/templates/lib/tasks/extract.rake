desc 'Extract information from given file'
namespace :extract do
  desc 'Extract plain text content from given file'
  task :content => :environment do
    ARGV.shift
    ARGV.select{|fn| File.file?(fn)}.each{|filename|
      puts "### Content extracted from : #{filename}"
      puts Document.extract_content_from(filename)
    }
  end
end
