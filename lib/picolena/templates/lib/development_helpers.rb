# D.query displays matching_documents for query, and returns the document
# with the highest score.
# Useful for development and debugging purposes 
#
# >> D.test
#  71 document(s) found for test:
#  for_test.txt
#  some_test_files.zip
#  plain.txt
#  another_plain.text
#  other_basic.PDF
#  basic.pdf
#  basic.odt
#  basic.tex
#  queens.for
#  README
#  ...........
#  => "spec/test_dirs/indexed/just_one_doc/for_test.txt (82.7%)"
class D
  def self.method_missing(query,*params)
    self[query.to_s] || super
  end
  def self.[](query)
    f=Finder.new(query.to_s)
    hits=f.total_hits
    if hits > 0 then
      puts "#{hits} document(s) found for #{query}:"
      f.matching_documents.each{|doc| puts "  "+doc.filename} 
      puts "  ..........." if hits > f.matching_documents.size
      f.matching_documents.first
    else
      puts "Nothing found for #{query}"
    end
  end
end
