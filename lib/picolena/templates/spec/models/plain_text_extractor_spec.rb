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

      if Picolena::Thumbnail::Extract && extractor.thumbnail_command then
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
    Document.extract_content_from(bin_file).should be_empty
  end

  it "should truncate extracted content when specified" do
    old_max_content_length = Picolena::IndexingConfiguration[:max_content_length]
    Picolena::IndexingConfiguration[:max_content_length] = 500
    begin
      full_content  = Document['spec/test_dirs/indexed/lang/lorca'].content
      trunc_content = Document['spec/test_dirs/indexed/lang/lorca'].content(:truncated)
      full_content.size.should > trunc_content.size
      full_content.starts_with?(trunc_content).should be_true
      trunc_content.size.should == Picolena::IndexingConfiguration[:max_content_length]
    ensure
      Picolena::IndexingConfiguration[:max_content_length] = old_max_content_length
    end
  end

  it "should not be prone to race conditions" do
    one_plain_text_filename     = 'spec/test_dirs/indexed/others/utf8.txt'
    another_plain_text_filename = 'spec/test_dirs/indexed/lang/goethe'

    first_extractor   = Document[one_plain_text_filename].extractor
    another_extractor = Document[another_plain_text_filename].extractor

    another_extractor.source.should == File.expand_path(another_plain_text_filename)
    first_extractor.source.should   == File.expand_path(one_plain_text_filename)
  end
end
