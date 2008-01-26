require 'rubygems'
require 'spec'

describe "Host indexing system" do
  %w{ferret paginator}.each  do |gem_name|
    it "should have #{gem_name} installed as a gem" do
      lambda {gem gem_name}.should_not raise_error
    end
  end
  
 %w{antiword pdftotext odt2txt html2text catppt xls2csv unrtf grep sed iconv file}.each  do |dependency|
    it "should have #{dependency} installed on system" do
       IO.popen("which #{dependency}"){|i| i.read.should_not be_empty}
    end
  end
end