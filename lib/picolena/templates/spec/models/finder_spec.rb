require File.dirname(__FILE__) + '/../spec_helper'

def revert_changes!(file,content)
  File.open(file,'w'){|might_have_been_modified|
    might_have_been_modified.write content
  }
end

describe Finder do
  before(:all) do
    # SVN doesn't like non-ascii filenames.
    revert_changes!('spec/test_dirs/indexed/others/bäñüßé.txt',"just to know if files are indexed with utf8 filenames")

    # To be sure this file has the right content
    revert_changes!("spec/test_dirs/indexed/others/placeholder.txt","Absorption and Adsorption cooling machines!!!")

    once_upon_a_time=Time.local(1982,2,16,20,42)
    a_bit_later=Time.local(1983,12,9,9)
    nineties=Time.local(1990)
    # Used for modification date search.
    File.utime(0, once_upon_a_time, 'spec/test_dirs/indexed/basic/basic.pdf')
    File.utime(0, a_bit_later, 'spec/test_dirs/indexed/yet_another_dir/office2003-word-template.dot')
    File.utime(0, nineties, 'spec/test_dirs/indexed/others/placeholder.txt')
    Indexer.index_every_directory(remove_first=true)
  end

  it "should find documents according to their basename when specified with basename:query" do
    matching_documents_filename=Finder.new("basename:crossed").matching_documents.collect{|d| d.filename}
    matching_documents_filename.should include("crossed.txt")
    matching_documents_filename.should include("crossed.text")
  end

  it "should find documents according to their filename when specified with file:query or filename:query" do
    Finder.new("filename:crossed.text").matching_documents.collect{|d| d.content}.should include("txt inside!")
    Finder.new("file:crossed.txt").matching_documents.collect{|d| d.content}.should include("text inside!")
  end

  it "should find documents according to their extension when specified with filetype:query" do
    Finder.new("filetype:odt").matching_documents.should_not be_empty
    Finder.new("filetype:pdf").matching_documents.should_not be_empty
  end

  it "should find documents according to their filename/basename/filetype even when unspecified" do
    Finder.new("crossed.text").matching_documents.should_not be_empty
    Finder.new("html").matching_documents.collect{|d| d.filename}.should include("zafh.net.html")
    Finder.new("crossed").total_hits.should >= 2
  end

  it "should give a boost to basename, filename and filetype in index" do
    index=Indexer.index
    index.field_infos[:basename].boost.should > 1.0
    index.field_infos[:filename].boost.should > 1.0
    index.field_infos[:filetype].boost.should > 1.0
  end

  it "should also index unreadable files with known mimetypes" do
    Finder.new("unreadable.pdf").matching_documents.should_not be_empty
    Finder.new("too_small.doc").matching_documents.should_not be_empty
  end

  it "should also index files with unknown mimetypes" do
    Finder.new("filetype:xyz").matching_document.basename.should == "ghjopdfg"
    Finder.new("filetype:abc").matching_document.filename.should == "asfg.abc"
    Finder.new("unreadable.png").matching_document.size.should == 19696
    #Support for xls has been added meanwhile. The test is still valid though.
    Finder.new("table.xls").matching_document.size.should == 8704
  end

  it "should also index files with upper/mixed case extension" do
    Finder.new("filetype:pdf").matching_documents.entries.find{|doc| doc.filename=="other_basic.PDF"}.should_not be_nil
    Finder.new("filetype:doc").matching_documents.entries.find{|doc| doc.filename=="other_too_small.dOc"}.should_not be_nil
  end

  it "should also index content of files with upper/mixed case extension" do
    Finder.new("'just another content test\nin a pdf file'").matching_documents.entries.find{|doc| doc.filename=="other_basic.PDF"}.should_not be_nil
  end

  it "should also accept utf8 queries" do
    lambda{Finder.new("Éric Mößer")}.should_not raise_error
  end

  it "should find documents according to their utf8 content" do
    Finder.new("Éric Mößer ext:pdf").matching_document.basename.should == "utf8"
    Finder.new("no me hace daño").matching_document.size.should == 30
    Finder.new("Éric Mößer filetype:pdf").matching_document.filename.should == "utf8.pdf"
  end

  it "should find documents according to their utf8 filenames" do
    Finder.new("bäñüßé").matching_document.content.should == "just to know if files are indexed with utf8 filenames"
  end

  it "should find documents according to their modification date" do
    Finder.new("date:<1982").matching_documents.should be_empty
    Finder.new("19831209*").matching_document.basename.should == "office2003-word-template"
    Finder.new("date:<1983").matching_document.filename.should == "basic.pdf"
    Finder.new("date:>=1989 AND date:<=1992").matching_document.filename.should == "placeholder.txt"
  end

  it "should not concatenate cells from xls file" do
    Finder.new("content:ABC").matching_documents.select{|doc| doc.extname==".xls"}.should be_empty
  end

  it "should not raise if an indexed document has been moved/deleted, but just ignore it" do
    @basic_dir='spec/test_dirs/indexed/basic/'
    @from=File.join(@basic_dir,'another_plain.text')
    @to=File.join(@basic_dir,'another_plain.text.bak')
    File.rename(@to,@from) if File.exists?(@to)
    begin
      lambda {
        File.rename(@from,@to)
      }.should change{Finder.new('filetype:text').matching_documents.size}.by(-1)
    ensure
      File.rename(@to,@from) if File.exists?(@to)
    end
  end

  it "should not index content of binary files"

  # Ferret sometimes SEGFAULT crashed with '*.pdf' queries
  it "should not crash while looking for *.pdf" do
    @finder=Finder.new("some query")
    lambda{@finder=Finder.new("*.pdf")}.should_not raise_error
    @finder.matching_documents.should_not be_empty
  end

  it "should use ? as placeholder" do
    Finder.new("A?sorption machines").matching_document.matching_content.should include("<<Absorption>> and <<Adsorption>> cooling <<machines>>!!!")
  end

  it "should use * as placeholder" do
    results=Finder.new("A*ption machines").matching_document.matching_content.should include("<<Absorption>> and <<Adsorption>> cooling <<machines>>!!!")
  end

  it "should not index those stupid Thumbs.db files" do
    Finder.new("Thumbs.db").matching_documents.should be_empty
    Finder.new("filetype:db").matching_documents.should_not be_empty
  end

  it "should keep content cached" do
    filename = "spec/test_dirs/indexed/others/placeholder.txt"
    content_before = "Absorption and Adsorption cooling machines!!!"
    some_doc=Document.new(filename)
    some_doc.content.should == content_before
    File.open(filename,'a'){|doc|
      doc.write("This line should not be indexed. It shouldn't be found in cache")
      }
    some_doc.content.should_not == content_before
    some_doc.cached.should == content_before
  end

  after(:all) do
    revert_changes!("spec/test_dirs/indexed/others/placeholder.txt","Absorption and Adsorption cooling machines!!!")
  end

#  Not sure about this spec!
#  English, or German?
#
#  TODO: Report!
#  Using custom Analyzer with StemFilter prevents * and ? to be used as placeholders
#  Better placeholders than stem!!!
#
#  it "should stem english words" do
#    complete_query="Beginning fished cats debates"
#    stem_queries=%w{beginning begin fished fish cats cat debate debater debaters fishing}
#    wrong_stem_queries=%w{beginni catty catties}
#    stem_en_file=Finder.new(complete_query).matching_document.filename
#    stem_queries.each{|q|
#      stem_results=Finder.new(q).matching_documents
#      stem_results.any?{|r| r.filename == stem_en_file}.should be_true
#    }
#    wrong_stem_queries.each{|q|
#      Finder.new(q).matching_documents.should be_empty
#    }
#  end
#
#  it "should stem german words" do
#    complete_query="Beginning fished cats debates"
#    stem_queries=%w{beginning begin fished fish cats cat debate}
#    wrong_stem_query="beginni fishe cats"
#    stem_en_file=Finder.new(complete_query).matching_document.filename
#    stem_queries.each{|q|
#      stem_results=Finder.new(q).matching_documents
#      puts q
#      stem_results.any?{|r| r.filename == stem_en_file}.should be_true
#    }
#  end
end
