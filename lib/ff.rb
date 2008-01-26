#!/usr/bin/env ruby
#
# ff - Search and index document files using Ferret
#
# Author:  Stuart Rackham <srackham@methods.co.nz>
# License: This source code is released under the MIT license.
# Home page: http://www.methods.co.nz/ff/
#
# Requisites:
# - Ferret 0.10.4 or better installed as a Ruby Gem.
#   See http://ferret.davebalmain.com/trac for Ferret installation.
# - The accompanying ferret_helper.rb file.
# - External text file converters documented in ferret_helper.rb file.
#

require 'pathname'
require 'fileutils'
require 'ferret_helper'

#require 'ferret_analyser_ext'
#Analyzer=CustomAnalyzer.new
Analyzer=Ferret::Analysis::StandardAnalyzer.new

include FerretHelper

INDEX_DIR = IndexSavePath rescue File.join('tmp/ferret_indexes/',RAILS_ENV || "development")

def puts_to_stderr_if_dev(string)
  $stderr.puts string if RAILS_ENV=="development"
end

def puts_to_stderr_if_not_test(string)
  $stderr.puts string if RAILS_ENV!="test"
end

# Add file +filename+ to the +index+.
def index_file(index, filename, mime_type=nil)
  fields = {}
  if mime_type then
    text = convert_to_text_string(filename, mime_type) if mime_type
    raise "empty document #{filename}" if text.strip.empty?
    fields[:content] = text
  end
  complete_path=File.expand_path(filename)
  fields[:complete_path] = complete_path
  fields[:md5]=Digest::MD5.hexdigest(complete_path)
  fields[:file] = File.basename(filename)
  fields[:basename] = File.basename(filename, File.extname(filename)).gsub(/_/,' ')
  fields[:filetype] = File.extname(filename)
  index << fields
end

# Recursively add all qualifying files in directory +dir+ to +index+.
def index_directory(index, dir, excludes, includes, counters)
  #Index just everything!
  Dir.glob(File.join(dir,"**/*.*"), File::FNM_CASEFOLD) do |filename|
    add = (includes.empty? or includes.any? { |m| File.fnmatch(m, filename, File::FNM_DOTMATCH) })
    if add
      add = (not excludes.any? { |m| File.fnmatch(m, filename, File::FNM_DOTMATCH) })
    end
    # Skip files in Darcs repositories or hidden directories.
    if add and File.file?(filename) and not filename =~ /(Thumbs\.db)/
      begin
        puts_to_stderr_if_dev("indexing: #{filename}")
        # Trying to guess MIME type from file contents is not reliable for text
        # files.  The strategy used here is to infer from file name extension
        # and rely on the convertor routine to fail if type is incorrect.
        mime_type = filename_mime_type(filename)
        counters[mime_type] ||= Struct::Counter.new(0,0,0,0)
        counters[mime_type].count += 1
        counters[mime_type].size += File.size(filename)
        start=Time.now
        index_file(index, filename, mime_type)
        counters[mime_type].time_needed += Time.now-start
      rescue => e
        puts_to_stderr_if_dev("indexing without content: #{e.message}")
        index_file(index, filename)
        counters[mime_type||'Unknown mime type'].without_content += 1
      end
    end
  end
end

def create_index(dirs, excludes=[], includes=[])
  FileUtils.mkpath File.dirname(INDEX_DIR)
  index = Ferret::Index::IndexWriter.new(:create => true, :path => INDEX_DIR, :analyzer => Analyzer)
    
  # Although not intuitively obvious, until I tokenized the file name, wildcard
  # file name searches did not return all matching documents.
  index.field_infos.add_field(:complete_path, :store => :yes, :index => :yes)
  index.field_infos.add_field(:content, :store => :yes, :index => :yes)
  index.field_infos.add_field(:basename, :store => :no, :index => :yes, :boost => 1.5)
  index.field_infos.add_field(:file, :store => :no, :index => :yes, :boost => 1.5)
  index.field_infos.add_field(:filetype, :store => :no, :index => :yes, :boost => 1.5)
  index.field_infos.add_field(:md5, :store=>:no, :index=>:yes)
    
  Struct.new('Counter', :size, :count, :without_content, :time_needed) unless Struct.constants.include?("Counter")
  counters = {}
  begin
    dirs.each { |dir| index_directory(index, dir, excludes, includes, counters) }
    index.optimize
  ensure
    index.close
  end
  counters.each_pair do |key,value|
    puts_to_stderr_if_not_test("\n#{key}:")
    puts_to_stderr_if_not_test("files indexed: #{value.count} (#{value.size} bytes)")
    puts_to_stderr_if_not_test("files without_content: #{value.without_content}") unless value.without_content.zero?
    unless value.count.zero? or value.without_content==value.count then
      puts_to_stderr_if_not_test("time needed: #{(value.time_needed*1000).to_i} ms")
      puts_to_stderr_if_not_test("avg. time needed: #{(value.time_needed*1000/(value.count-value.without_content)).to_i} ms/file")
    end
  end
  total_count = counters.values.inject(0) {|sum,count| sum + count.count}
  total_size = counters.values.inject(0) {|sum,count| sum + count.size}
  total_without_content = counters.values.inject(0) {|sum,count| sum + count.without_content}
  total_time_needed = counters.values.inject(0) {|sum,count| sum + count.time_needed}
  puts_to_stderr_if_not_test("\ntotal files indexed: #{total_count} (#{total_size} bytes)")
  puts_to_stderr_if_not_test("total files without_content: #{total_without_content}") unless total_without_content.zero?
  unless total_count.zero? or total_count==total_without_content then
    puts_to_stderr_if_not_test("total time needed: #{(total_time_needed*1000).to_i} ms")
    puts_to_stderr_if_not_test("avg. time needed: #{(total_time_needed*1000/(total_count-total_without_content)).to_i} ms/file")
  end
end
