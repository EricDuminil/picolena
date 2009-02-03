class String
  # Creates a "probably unique" id with the desired length, composed only of lowercase letters.
  def base26_hash(length=Picolena::HashLength)
    Digest::MD5.hexdigest(self).to_i(16).to_s(26).tr('0-9a-p', 'a-z')[-length,length]
  end
end

module Enumerable
  # Similar to Enumerable#each, but creates a new thread for each element.
  # Used for the indexer to make it multi-threaded.
  # It ensures that threads are joined together before returning.
  def each_with_thread(&block)
    tds=self.collect{|elem|
      Thread.new(elem) {|elem|
        block.call(elem)
      }
    }
    tds.each{|aThread| aThread.join}
  end
end

class Array
  # Returns a partition of n arrays.
  # Transposition is used to avoid getting arrays that are too different.
  #   >> (0..17).to_a.in_transposed_slices(5)
  #   => [[0, 5, 10, 15], [1, 6, 11, 16], [2, 7, 12, 17], [3, 8, 13], [4, 9, 14]]
  # while
  #   >> (0..17).enum_slice(5).to_a
  #   => [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17]]
  #
  # If some folders contain big files and some others contain small ones,
  # every indexing thread will get some of both!
  def in_transposed_slices(n)
    # no need to compute anything if n==1
    return [self] if n==1
    # Array#transpose would raise if Array is not a square array of arrays.
    i=n-self.size%n
    # Adds nils so that size is a multiple of n,
    # cuts array in slices of size n,
    # transposes to get n slices,
    # and removes added nils.
    (self+[nil]*i).enum_slice(n).to_a.transpose.collect{|e| e.compact}
  end
end

class Hash
  def add(category)
    self[category]||={:size=>0}
    self[category][:size]+=1
  end
end

class File
  # Returns the filetype of filename as a symbol.
  # Returns :no_extension unless an extension is found
  #  >> File.ext_as_sym("test.pdf")
  #  => :pdf
  #  >> File.ext_as_sym("test.tar.gz")
  #  => :gz
  #  >> File.ext_as_sym("test")
  #  => :no_extension
  def self.ext_as_sym(filename)
    File.extname(filename).sub(/^\./,'').downcase.to_sym rescue :no_extension
  end

  # Returns a probable encoding for a given plain text file
  # If source is a html file, it parses for metadata to retrieve encoding,
  # and uses file -i otherwise.
  # Returns iso-8859-15 instead of iso-8859-1, to be sure € char can be
  # encoded
  def self.encoding(source)
    parse_for_charset="grep -io charset=[a-z0-9\\-]* | sed 's/charset=//i'"
    if File.extname(source)[0,4]==".htm" then
      enc=%x{head -n20 \"#{source}\" | #{parse_for_charset}}.chomp
    else
      enc=%x{file -i \"#{source}\"  | #{parse_for_charset}}.chomp
    end
    #iso-8859-15 should be used instead of iso-8859-1, for € char
    case enc
     when "iso-8859-1"
       "iso-8859-15"
     when "unknown"
       ""
     else
       enc
     end
  end

  # Returns the content of a file and removes it after.
  # Could be used to read temporary output file written by a PlainTextExtractor.
  def self.read_and_remove(filename)
    content=read(filename)
    FileUtils.rm filename, :force=>true
    content
  end
 
  # Returns nil unless filename is a plain text file.
  # It requires file command.
  # NOTE: What to use for Win32?
  def self.plain_text?(filename)
    %x{file -i "#{filename}"} =~ /: text\//
  end

  # For a given file, returns the path at which a thumbnail should be saved
  def self.thumbnail_path(filename, public_dir=false)
    thumb=expand_path(filename).base26_hash+'.jpg'
    public_dir ? File.join('thumbnails', thumb) : File.join(RAILS_ROOT,  'public/images/thumbnails', thumb)
  end
end
