require File.dirname(__FILE__) + '/../spec_helper'

describe "PlainTextExtractors" do
  before(:all) do
    Indexer.ensure_index_existence
  end

  PlainTextExtractor.all.each{|extractor|
    extractor.exts.each{|ext|
      should_extract= "should be able to extract content from #{extractor.description} (.#{ext})"
      content_and_file_examples_for_this_ext=extractor.content_and_file_examples.select{|content,file| File.ext_as_sym(file)==ext}
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
        ## add this line to the corresponding extractor in lib/extractors:
        # which_should_for_example_extract 'some content', :from => 'a file you could add in spec/test_dirs/indexed/'
        it should_extract
      end
    }
  }

  it "should not extract content of binary files" do
    PlainTextExtractor.extract_content_from("spec/test_dirs/indexed/others/BIN_FILE_WITHOUT_EXTENSION").should be_blank
  end
end
