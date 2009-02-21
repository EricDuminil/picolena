require 'plain_text_extractor_dsl'

# PlainTextExtractor is the class responsible for extracting plain text contents from
# different documents filetypes (.doc, .html, .pdf, .od?), as defined in
#   lib/plain_text_extractors/*.rb
class PlainTextExtractor
  include PlainTextExtractorDSL
  class<<self
    # Returns every defined extractor
    def all
      Picolena::Extractors
    end

    # Add an extractor to the extractors list
    def add(extractor)
      all<<extractor
    end

    # Returns every required dependency for every defined extractor
    def dependencies
      @@dependencies||=all.collect{|extractor| extractor.dependencies}.flatten.compact.uniq.sort
    end

    # Returns every supported file extensions
    def supported_extensions
      @@supported_exts||=all.collect{|extractor| extractor.exts}.flatten.compact.uniq
    end

    # Finds which extractor should be used for a given file.
    # TODO: Rename this method, which does more than barely finding an extractor
    def find_by_filename(filename)
      ext=File.ext_as_sym(filename)
      returning find_by_extension(ext).dup do |found_extractor|
        found_extractor.source=filename
      end
    end

    # Finds which extractor should be used for a given file, according to its extension
    # Raises if the file is unsupported.
    def find_by_extension(ext)
      all.find{|extractor| extractor.exts.include?(ext)} || raise(ArgumentError, "no convertor for .#{ext}")
    end

    # Launches extractor on given file and outputs plain text result
    def extract_content_from(source)
      find_by_filename(source).extract_content
    end

    # Launches extractor on given file and outputs plain text result and language (if found)
    def extract_information_from(source)
      find_by_filename(source).extract_information
    end

    # Returns which language guesser should be used by the system.
    # Returns nil if none is found.
    def language_guesser
      @@language_guesser||=('mguesser -n1' if 'mguesser'.installed?)
    end
  end

  attr_accessor :source

  # Parses commands in order to know which programs are needed.
  # rspec will then check that every dependecy is installed on the system
  def dependencies
      [@dependencies, command.dependencies, thumbnail_command.dependencies].flatten
  end

  ## Conversion part
  # Returns plain text content of source file
  def extract_content
    if command.is_a?(String) then
      # If command is a String, launch it via system(command).
      if command.include?('DESTINATION') then
        # If command includes 'DESTINATION' keyword,
        # launches the command and returns the content of
        # DESTINATION file.
        silently_execute(specific_command)
        File.read_and_remove(destination)
      else
        # Otherwise, launches the command and returns STDOUT.
        silently_execute(specific_command)
      end
    else
      # command is a Block.
      # Returns the result of command.call,
      # with source file as parameter.
      command.call(source)
    end
  end

  # Returns plain text content and language of source file,
  # using mguesser to guess used language.
  # This method only returns probable language if the content is bigger than 500 chars
  # and if probability score is higher than 90%.
  def extract_information
    extract_thumbnail
    content=extract_content

    return {:content => content} unless [# Is LanguageRecognition turned on? (cf config/custom/picolena.rb)
                                         Picolena::UseLanguageRecognition,
                                         # Is a language guesser already installed?
                                         PlainTextExtractor.language_guesser,
                                         # Language recognition is too unreliable for small files.
                                         content.size > 500].all?

    language=IO.popen(PlainTextExtractor.language_guesser,'w+'){|lang_guesser|
      lang_guesser.write content
      lang_guesser.close_write
      output=lang_guesser.read
      if output=~/^([01]\.\d+)\t(\w+)\t(\w+)/ then
        score, lang, encoding = $1.to_f, $2, $3
        # Language recognition isn't reliable if score is too low.
        lang unless score<0.9
      end
    }

    {:content => content, :language => language}
  end

  # Tries to extract a thumbnail from source.
  # Doesn't do anything if thumbnail_command isn't defined for the corresponding filetype.
  def extract_thumbnail
    silently_execute(specific_thumbnail_command) if thumbnail_command
  end

  private

  # destination method can be used by some conversion command that cannot output to stdout (example?)
  # a file containing plain text result will first be written by command, and then be read by extract_content.
  def destination
    require 'tmpdir'
    @@temp_file_as_destination ||= File.join(Dir::tmpdir,"ferret_#{Time.now.to_i}")
  end

  # Replaces generic command with specific source and destination (if specified) files
  def specific_command
    command.sub('SOURCE','"'<<source<<'"').sub('DESTINATION','"'<<destination<<'"')
  end

  # Replaces generic command with specific source and thumbnail (if specified) files
  def specific_thumbnail_command
    thumbnail_command.sub('SOURCE','"'<<source<<'"').sub('THUMBNAIL','"'<<File.thumbnail_path(source)<<'"')
  end
end
