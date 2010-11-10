xml.instruct!
xml.picolena_response do
  xml.query @query
  xml.total_hits @total_hits
  xml.time_needed @time_needed
  xml.found_documents do
    @matching_documents.each do |document|
      xml.document do
        xml.id document.probably_unique_id
        xml.filename document.filename
        xml.score document.score*100
        xml.matching_content document.matching_content
        xml.containing_directory document.alias_path
        xml.filesize number_to_human_size(document.size)
        xml.modified_on document.pretty_cache_mdate
        xml.download_url download_document_url(document.probably_unique_id)
      end
    end
  end
end
