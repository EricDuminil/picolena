require File.dirname(__FILE__) + '/../spec_helper'

describe Indexer do
  it "should have at least 32MB memory allocated" do
    Indexer.index.writer.max_buffer_memory.should > 2**25-1
  end
end
