desc 'Extract information from given file'
namespace :extract do
  desc 'Extract plain text content from given file'
  task :content => :environment do
    ARGV.shift
    ARGV.select{|fn| File.file?(fn)}.each{|filename|
      begin
        content=PlainTextExtractor.extract_content_from(filename)
        puts "### Content extracted from : #{filename}"
        puts content
      rescue => e
        puts "### No content extracted from #{filename} (#{e.message})"
      end
    }
  end
end
