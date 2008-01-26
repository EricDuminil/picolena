require "tmpdir"
require File.dirname(__FILE__) + '/../spec_helper'

ext_and_content_examples={
  :doc=>'district heating',
  :odt=>'OpenOffice.org',
  :txt=>'text inside!',
  :text=>'txt inside!',
  :pdf=>'in a pdf file',
  :html=>'zentrum für angewandte forschung an fachhochschulen nachhaltige energietechnik Baden-Württemberg',
  :htm=>'le monde',
  :ppt=>'unofficial written by OOo Impress',
  :xls=>'Some text (should be indexed!)',
  :tex=>'should index LaTeX too',
  :rtf=>'Resampling when limiting',
  :rb=>'Hello world!'
}

encoding_and_content_examples={'utf-8'=>"püöüökäößß AND ßklüöü",
  'iso-8859-1'=>"Themenliste für Adsorptionskälte",
  'iso-8859-15'=>"F€rnwärme"
}

describe Finder do
  
  before(:all) do
    File.open('spec/test_dirs/indexed/others/bäñüßé.txt','w'){|weird_file|
      weird_file.write "just to know if files are indexed with utf8 filenames"
     }
    
    Finder.force_index_creation
  end

  ext_and_content_examples.each_pair do |ext,content_to_be_found|
    it "should be able to find .#{ext} documents according to their content" do
      finder=Finder.new(content_to_be_found)
      finder.execute!
      matching_documents=finder.matching_documents
      matching_documents_extname=matching_documents.collect{|d| d.extname}
      matching_documents_extname.should include(".#{ext}")
    end
  end
  
  it "should find documents according to their basename when specified with basename:query" do
    matching_documents_filename=Finder.new("basename:crossed").matching_documents.collect{|d| d.filename}
    matching_documents_filename.should include("crossed.txt")
    matching_documents_filename.should include("crossed.text")
  end
  
  it "should find documents according to their filename when specified with file:query" do
    Finder.new("file:crossed.text").matching_documents.collect{|d| d.content}.should include("txt inside!")
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
    @finder=Finder.new("some query")
    @finder.index.field_infos[:basename].boost.should > 1.0
    @finder.index.field_infos[:file].boost.should > 1.0
    @finder.index.field_infos[:filetype].boost.should > 1.0
  end
  
  it "should also index unreadable files with known mimetypes" do
    Finder.new("unreadable.pdf").matching_documents.should_not be_empty
    Finder.new("too_small.doc").matching_documents.should_not be_empty
  end
  
  it "should also index files with unknown mimetypes" do
    Finder.new("filetype:xyz").matching_documents.first.basename.should == "ghjopdfg"
    Finder.new("filetype:abc").matching_documents.first.filename.should == "asfg.abc"
    Finder.new("unreadable.png").matching_documents.first.size.should == 19696
    #Support for xls has been added meanwhile. The test is still valid though.
    Finder.new("table.xls").matching_documents.first.size.should == 8704
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
    Finder.new("Éric Mößer").matching_documents.first.basename.should == "utf8"
    Finder.new("no me hace daño").matching_documents.first.size.should == 30
    Finder.new("Éric Mößer filetype:pdf").matching_documents.first.filename.should == "utf8.pdf"
  end
  
  it "should find documents according to their utf8 filenames" do
    Finder.new("bäñüßé").matching_documents.first.content.should == "just to know if files are indexed with utf8 filenames"
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
  
  it "should also index files without extension?"
  
  it "should also index files with ' in filename"
  
  it "should not crash while looking for *.pdf" do
    @finder=Finder.new("some query")
    lambda{@finder=Finder.new("*.pdf")}.should_not raise_error
    @finder.matching_documents.should_not be_empty
  end
  
  it "should not be case sensitive" do
    a=Finder.new("test").total_hits
    b=Finder.new("TEst").total_hits
    c=Finder.new("tesT").total_hits
    a.should == b
    b.should == c
  end
  
  #TODO: remove language specific ops from specs
  it "should accept ~ WIE and - NICHT as boolean ops" do
    fuzzy_query=Finder.new("test~").total_hits
    test_query=Finder.new("test").total_hits
    minus_query=Finder.new("WIE test NICHT test").total_hits
     (fuzzy_query-test_query).should == minus_query
  end
  
  it "should accept AND/UND and OR/ODER as boolean ops" do
    ['OR', 'ODER'].each{|or_bool|
      ['AND', 'UND'].each{|and_bool|
        or_query=Finder.new("test #{or_bool} another").total_hits
        and_query=Finder.new("test #{and_bool} another").total_hits
        test_query=Finder.new("test").total_hits
        another_query=Finder.new("another").total_hits
         (test_query+another_query-and_query).should == or_query
      }
    }
  end
  
  it "should use AND as default boolean ops" do
    or_query=Finder.new("test OR another").total_hits
    and_query=Finder.new("test another").total_hits
    test_query=Finder.new("test").total_hits
    another_query=Finder.new("another").total_hits
     (test_query+another_query-and_query).should == or_query
    and_query.should <= or_query
    and_query.should <= test_query
    and_query.should <= another_query
  end
  
  it "should convert UND to AND and ODER to OR only as whole-word" do
    Finder.new("STRALSUND UND BRODERBUND").matching_documents.should_not be_empty
  end
  
  it "should use ? as placeholder" do
    results=Finder.new("A?sorption machines").matching_documents
    results.should_not be_empty
    results.first.matching_content.should include("<<Absorption>> and <<Adsorption>> cooling <<machines>>!!!")
  end
  
  it "should use * as placeholder" do
    results=Finder.new("A*ption machines").matching_documents
    results.should_not be_empty
    results.first.matching_content.should include("<<Absorption>> and <<Adsorption>> cooling <<machines>>!!!")
  end

  it "should not index those stupid Thumbs.db files" do
    Finder.new("Thumbs.db").matching_documents.should be_empty
    Finder.new("filetype:db").matching_documents.should_not be_empty
  end
  
  encoding_and_content_examples.each_pair do |encoding,content_to_be_found|
    it "should also index non-ascii characters from #{encoding} txt files" do
      one_iso_doc=Finder.new(content_to_be_found).matching_documents
      one_iso_doc.should_not be_empty
      one_iso_doc.first.basename.should == encoding
    end
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
#    stem_en_file=Finder.new(complete_query).matching_documents.first.filename
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
#    stem_en_file=Finder.new(complete_query).matching_documents.first.filename
#    stem_queries.each{|q|
#      stem_results=Finder.new(q).matching_documents
#      puts q
#      stem_results.any?{|r| r.filename == stem_en_file}.should be_true
#    }
#  end
end
