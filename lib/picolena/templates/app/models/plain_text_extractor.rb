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

    # Finds which extractor should be used for a given file, according to its extension
    def find_by_extension(ext)
      all.find{|extractor| extractor.exts.include?(ext)}
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
  #
  # If desired, result can be truncated to avoid too big a data :
  # DBMS might expect a maximum field size, and the indexer might ignore
  # any term after the N first ones.
  def extract_content(truncate=false)
    content=if command.is_a?(String) then
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

    content||=""
    content.strip!
    truncate ? content[0...Picolena::IndexingConfiguration[:max_content_length]] : content
  end

  # Returns plain text content and language of source file,
  # using mguesser to guess used language.
  def extract_content_and_language(truncate=false)
    [content = extract_content(truncate), find_language(content)]
  end

  def extract_thumbnail
    case thumbnail_command
      when String : silently_execute(specific_thumbnail_command)
      when Proc   : thumbnail_command.call(source, File.thumbnail_path(source))
    end
  end

  private

  # Is it worth it using language recognition?
  # Content needs to have at leat 500 chars in order for recognition to be reliable.
  def use_language_recognition?(content_size)
    Picolena::UseLanguageRecognition &&
    PlainTextExtractor.language_guesser &&
    content_size > 500
  end

  # This method only returns probable language if the content is bigger than 500 chars
  # and if probability score is higher than 90%.
  def find_language(content)
    IO.popen(PlainTextExtractor.language_guesser,'w+'){|lang_guesser|
      lang_guesser.write content
      lang_guesser.close_write
      output=lang_guesser.read
      if output=~/^([01]\.\d+)\t(\w+)\t(\w+)/ then
      score, lang, encoding = $1.to_f, $2, $3
        # Language recognition isn't reliable if score is too low.
        lang if score>0.9
      end
    } if content && use_language_recognition?(content.size)
  end

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
    #TODO: DRY!
    thumbnail_command.sub('SOURCE','"'<<source<<'"').sub('THUMBNAIL','"'<<File.thumbnail_path(source)<<'"').sub('QUALITY','"'<<Picolena::Thumbnail::Quality<<'"').sub('WIDTH','"'<<Picolena::Thumbnail::Width<<'"').sub('HEIGHT','"'<<Picolena::Thumbnail::Height<<'"')
  end
end

# Extractor that is attributed to non supported Documents,
# to ease delegation from Document to PlainTextExtractor
class EmptyExtractor
  def self.instance
    @@singleton||=EmptyExtractor.new
  end

  def extract_content_and_language(*p)
    ['',nil]
  end

  def extract_thumbnail
  end

  def extract_content(*p)
    ''
  end

  def mime
    'application/octet-stream'
  end
end
