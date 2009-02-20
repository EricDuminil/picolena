require File.dirname(__FILE__) + '/../spec_helper'

describe "PlainTextExtractors" do
  before(:all) do
    Indexer.ensure_index_existence
  end

  PlainTextExtractor.all.each{|extractor|
    extractor.exts.each{|ext|
      should_extract_content  = "should be able to extract content from #{extractor.description} (.#{ext})"
      should_extract_thumbnail= "should be able to extract thumbnail from #{extractor.description} (.#{ext})"
      content_and_file_examples_for_this_ext=extractor.content_and_file_examples.select{|content,file| File.ext_as_sym(file)==ext}
      if content_and_file_examples_for_this_ext.empty? then
        ## It means that the spec for this extension file is "Not yet implemented"!
        ## add this line to the corresponding extractor in lib/extractors:
        # which_should_for_example_extract 'some content', :from => 'a file you could add in spec/test_dirs/indexed/'
        it should_extract_content
      else
        it should_extract_content do
          content_and_file_examples_for_this_ext.each{|content_example,file_example|
            finder=Finder.new(content_example)
            finder.execute!
            matching_documents=finder.matching_documents
            matching_documents_filenames=matching_documents.collect{|d| d.filename}
            matching_documents_filenames.should include(file_example)
          }
        end
      end

      if extractor.thumbnail_command then
        doc=Document.find_by_extension(ext)
        if doc then
          it should_extract_thumbnail do
            thumb_path=doc.send(:thumbnail_path)
            # NOTE: This doesn't seem to work, why?
            #  File.should exist(doc.send(:thumbnail_path))
            File.exist?(thumb_path).should be_true
            # NOTE: It seems that ffmpegthumbnailer outputs a png file even with -o output.jpg
            %x(file -ib #{thumb_path}).chomp.should =~ /image\/(jpeg|png)/
          end
        else
          it should_extract_thumbnail
        end
      end
    }
  }

  it "should not extract content of binary files" do
    bin_file="spec/test_dirs/indexed/others/BIN_FILE_WITHOUT_EXTENSION"
    Document.extract_content_from(bin_file).should be_nil
  end
end
