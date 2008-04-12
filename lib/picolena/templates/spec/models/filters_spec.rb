require File.dirname(__FILE__) + '/../spec_helper'

describe "Filters" do
  before(:all) do
    IndexReader.ensure_existence
  end  
  
  PlainText.filters.each{|filter|
    filter.exts.each{|ext|
      should_extract= "should be able to extract content from #{filter.description} (.#{ext})"
      content_and_file_examples_for_this_ext=filter.content_and_file_examples.select{|content,file| File.ext_as_sym(file)==ext}
      unless content_and_file_examples_for_this_ext.empty? then
        it should_extract do
          content_and_file_examples_for_this_ext.each{|content_example,file_example|
            finder=Finder.new(content_example)
            finder.execute!
            matching_documents=finder.matching_documents
            matching_documents_filenames=matching_documents.collect{|d| d.filename}
            matching_documents_filenames.should include(file_example)
          }
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