require File.dirname(__FILE__) + '/../spec_helper'

describe Indexer do
  it "should have at least 32MB memory allocated" do
    Indexer.index.writer.max_buffer_memory.should > 2**25-1
  end

  it "should know the time it was updated" do
    Indexer.should respond_to(:last_update)
    begin
      Indexer.last_update.should be_kind_of(Time)
    rescue
      Indexer.last_update.should == "none"
    end
  end
  
  it "should give a boost to basename, filename and filetype in index" do
    index=Indexer.index
    index.field_infos[:basename].boost.should > 1.0
    index.field_infos[:filename].boost.should > 1.0
    index.field_infos[:filetype].boost.should > 1.0
  end

  it "should use at least one thread" do
    Picolena::IndexingConfiguration[:threads_number].should_not be_nil
    Picolena::IndexingConfiguration[:threads_number].should > 0
  end
end
