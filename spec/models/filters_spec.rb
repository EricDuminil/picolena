require File.dirname(__FILE__) + '/../spec_helper'

describe "Filters" do
  before(:all) do
    Finder.ensure_that_index_exists_on_disk
  end  
  
  PlainText.filters.each{|filter|
    filter.exts.each{|ext|
      should_extract= "should be able to extract content from #{filter.description} (.#{ext})"
      content_example,file_example=filter.content_and_file_examples.find{|content,file| File.ext_as_sym(file)==ext}
      if content_example then
        it should_extract do
          finder=Finder.new(content_example)
          finder.execute!
          matching_documents=finder.matching_documents
          matching_documents_filenames=matching_documents.collect{|d| d.filename}
          matching_documents_filenames.should include(file_example)
        end
      else
        ## It means that the spec for this extension file is "Not yet implemented"!
        ## add this line to the corresponding filter in lib/filters:
        # which_should_for_example_extract 'some content', :from => 'a file you could add in spec/test_dirs/indexed/'
        it should_extract
      end
    }
  }
end