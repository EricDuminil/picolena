require File.dirname(__FILE__) + '/../spec_helper'

def matching_document_for(query)
  # Returns matching document for any given query only if
  # exactly one document is found.
  # Specs don't pass otherwise.
  matching_documents=Finder.new(query).matching_documents
  matching_documents.size.should == 1
  matching_documents.first
end


describe Finder do
  before(:all) do
    Globalite.language = :en

    once_upon_a_time=Time.local(1982,2,16,20,42)
    a_bit_later=Time.local(1983,12,9,9)
    nineties=Time.local(1990)
    # Used for modification date search.
    File.utime(0, once_upon_a_time, 'spec/test_dirs/indexed/basic/basic.pdf')
    File.utime(0, a_bit_later, 'spec/test_dirs/indexed/yet_another_dir/office2003-word-template.dot')
    File.utime(0, nineties, 'spec/test_dirs/indexed/others/placeholder.txt')
    File.utime(0, Time.now+2.days, 'spec/test_dirs/indexed/lang/goethe')
    File.utime(0, Time.now+1.day, 'spec/test_dirs/indexed/lang/lorca')
    Indexer.index_every_directory(remove_first=true)
  end

  it "should find documents according to their basename when specified with basename:query" do
    matching_documents_filename=Finder.new("basename:crossed").matching_documents.collect{|d| d.filename}
    matching_documents_filename.should include("crossed.txt")
    matching_documents_filename.should include("crossed.text")
  end

  it "should find documents according to their filename when specified with file:query or filename:query" do
    matching_document_for("file:crossed.text").content.should include("txt inside!")
    matching_document_for("file:crossed.txt").content.should include("text inside!")
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

  it "should find documents according to parts of their alias_path" do
    media_files=Dir["#{RAILS_ROOT}/spec/test_dirs/indexed/media/*"]
    Finder.new("media").total_hits.should >= media_files.size
    Finder.new("nested indexed").matching_documents.collect{|d| d.filename}.should include("ReadMe.rtf")
    matching_document_for("test_dirs yet_another_dir ext:xlsx").basename.should == "office2007-excel"
  end

  it "should also index unreadable files with known mimetypes" do
    Finder.new("unreadable.pdf").matching_documents.should_not be_empty
    Finder.new("too_small.doc").matching_documents.should_not be_empty
  end

  it "should also index files with unknown mimetypes" do
    matching_document_for("filetype:xyz").basename.should == "ghjopdfg"
    matching_document_for("filetype:abc").filename.should == "asfg.abc"
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
    matching_document_for("Éric Mößer ext:pdf").basename.should == "utf8"
    matching_document_for("no me hace daño").filename.should == "utf8.txt"
    matching_document_for("Éric Mößer filetype:pdf").filename.should == "utf8.pdf"
  end

  it "should find documents according to their utf8 filenames" do
    matching_document_for("bäñüßé").content.should == "just to know if files are indexed with utf8 filenames"
  end

  it "should find documents according to their modification date"
    ## Not implemented yet!
    # matching_document_for("19831209").basename.should == "office2003-word-template"
    # matching_document_for("19820216").basename.should == "basic"

  it "should find documents according to their modification year"
    ## Not implemented yet!
    # Finder.new("date:<1982").matching_documents.should be_empty
    # matching_document_for("date:<1983").filename.should == "basic.pdf"
    # matching_document_for("date:1982").filename.should == "basic.pdf"
    # matching_document_for("year:1983").filename.should == "basic.pdf"
    # matching_document_for("date:>=1989 AND date:<=1992").filename.should == "placeholder.txt"

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

  it "should not raise if IndexedDirectories has been modified, but just ignore files that are not included anymore" do
    @original_indexed_dirs=Picolena::IndexedDirectories.dup
    # There's only one file ('for_test.txt') in this directory
    # This should be the only one found once IndexedDirectories has been modified.
    just_one_doc=File.expand_path(File.join(RAILS_ROOT, 'spec/test_dirs/indexed/just_one_doc'))
    begin
      lambda {
        Picolena::IndexedDirectories.replace(just_one_doc => '//just_one_doc/')
        #NOTE: total_hits will still be >15, but matching_documents.size should == 1
        #NOTE: this spec is broken : if the 10 first documents are not included in Picolena::IndexedDirectories, then matching_documents.empty?
      }.should change{Finder.new('filetype:txt','relevance',1,20).matching_documents.size}.to(1)
    ensure
      Picolena::IndexedDirectories.replace(@original_indexed_dirs)
    end
  end

  # Ferret sometimes SEGFAULT crashed with '*.pdf' queries
  it "should not crash while looking for *.pdf" do
    @finder=Finder.new("some query")
    lambda{@finder=Finder.new("*.pdf")}.should_not raise_error
    @finder.matching_documents.should_not be_empty
  end

  it "should use ? as placeholder" do
    matching_document_for("A?sorption machines").matching_content.should include("<<Absorption>> and <<Adsorption>> cooling <<machines>>!!!")
  end

  it "should use * as placeholder" do
    results=matching_document_for("A*ption machines").matching_content.should include("<<Absorption>> and <<Adsorption>> cooling <<machines>>!!!")
  end

  it "should not index those stupid Thumbs.db files" do
    Finder.new("Thumbs.db").matching_documents.should be_empty
    Finder.new("filetype:db").matching_documents.should_not be_empty
  end

  it "should be able to sort results by mtime" do
    lambda{@recent_docs=Finder.new('*', 'date').matching_documents}.should_not raise_error
    # mtime has been modified before indexing
    #   File.utime(0, Time.now+2.days, 'spec/test_dirs/lang/goethe')
    #   File.utime(0, Time.now+1.day, 'spec/test_dirs/lang/lorca')
    # so that those 2 docs should show up at the top of the list
    @recent_docs.first.filename.should  == 'goethe'
    @recent_docs.second.filename.should == 'lorca'
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
