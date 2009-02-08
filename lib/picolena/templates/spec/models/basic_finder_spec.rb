require "tmpdir"
require File.dirname(__FILE__) + '/../spec_helper'

describe "Finder without index on disk" do
  before(:all) do
    @original_index_path=Picolena::IndexSavePath.dup
    @original_indexed_dirs=Picolena::IndexedDirectories.dup
    @new_index_path=File.join(Dir::tmpdir,'ferret_tst')
    Picolena::IndexSavePath.replace(@new_index_path)
    Picolena::MetaIndexPath.replace(File.join(@new_index_path,'meta'))
    FileUtils.mkpath Picolena::MetaIndexPath
  end

  before(:each) do
    Indexer.clear!
    Finder.send(:class_variable_set,'@@last_reload',nil)
  end

  it "should create index" do
    new_dir=File.expand_path(File.join(RAILS_ROOT, 'spec/test_dirs/indexed/just_one_doc'))
    Picolena::IndexedDirectories.replace(new_dir => '//justonedoc/')
    lambda {@finder_with_new_index=Finder.new("test moi")}.should change(Indexer, :index_exists?).from(false).to(true)
    File.exists?(File.join(@new_index_path,'_0.cfs')).should be_true
    Indexer.index.size.should >0
  end

  it "should raise if index is still empty after trying to create it" do
    Picolena::IndexedDirectories.replace({'spec/test_dirs/empty_folder'=>'//empty_folder/'})
    lambda {Finder.new("doesn't matter anyway")}.should raise_error(IndexError, "no document found")
    File.exists?(File.join(@new_index_path,'_0.cfs')).should be_false
  end

  after(:all) do
    Picolena::IndexedDirectories.replace(@original_indexed_dirs)
    Picolena::IndexSavePath.replace(@original_index_path)
    Picolena::MetaIndexPath.replace(File.join(@original_index_path,'meta'))
    FileUtils.remove_entry_secure(@new_index_path)
  end
end


fields={
  # description       => key
  :content            => :content,
  :complete_path      => :complete_path,
  :basename           => :basename,
  :filename           => :filename,
  :extension          => :filetype,
  :modification_time  => :modified,
  :probably_unique_id => :probably_unique_id,
  :language           => :language
}

describe "Basic Finder" do
  before(:all) do
    Indexer.index_every_directory(remove_first=true)
  end

  it "should accept one parameter as query, 1 optional for sorting results and 2 optionals for paginating" do
    lambda {Finder.new}.should raise_error(ArgumentError, "wrong number of arguments (0 for 1)")
    # show first page with 10 results per page
    lambda {Finder.new("a b")}.should_not raise_error
    # show second page
    lambda {Finder.new("a", "by_date")}.should_not raise_error
    # show first page with 15 results
    lambda {Finder.new("a",  "by_date", 1, 15)}.should_not raise_error
    # Too many parameters
    lambda {Finder.new("a",  "by_date", 10, 20, 30)}.should raise_error(ArgumentError, "wrong number of arguments (5 for 4)")
  end

  it "should return matching documents if executed successfully" do
    finder_with_valid_query=Finder.new("district heating")
    finder_with_valid_query.should respond_to(:matching_documents)

    matching_documents=finder_with_valid_query.matching_documents
    matching_documents.should_not be_empty

    matching_documents_filenames=matching_documents.collect{|d| d.filename}
    matching_documents_filenames.should include("Simulation of district heating systems for evaluation of real-time control strategies.pdf")
    matching_documents_filenames.should include("Types of malfunction in DH substations.doc")
  end

  it "should know if it has been executed" do
    @finder=Finder.new("some query")
    lambda {@finder.execute!}.should change(@finder, :executed?).from(false).to(true)
  end

  it "should not warn anything if index is up to date"

  it "should warn if index is not up to date"

  fields.each_pair do |description,field_name|
    it "should index #{description} as :#{field_name}" do
      Indexer.index.field_infos[field_name].should be_an_instance_of(Ferret::Index::FieldInfo)
    end
  end

  it "should know how much time was needed for execution" do
    finder=Finder.new("yet another stupid query")
    finder.should_not be_executed
    finder.time_needed.should > 0
    finder.should be_executed
  end

  it "should not need more than 100ms to find documents" do
    finder=Finder.new("district heating")
    finder.execute!
    finder.time_needed.should < 0.1
  end
end
