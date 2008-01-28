# Wrapper methods for converting PDF, HTML, Open Document and Microsoft Word
# files to text for the Ferret index analysers.
#
# Author:  Stuart Rackham <srackham@methods.co.nz>
# License: This source code is released under the MIT license.
#
# Include as instance methods of the client class:
#
#   include FerretHelper
#
# or add them as class methods to a client class:
#
#   extend FerretHelper
#
# File conversion to indexable text and MIME type detection rely on the
# following external applications (the following list was tested on Debian
# based Ubuntu Linux 7.10):
#
# MIME type detection:
#   Program: file(1)
#   Test version: 4.21
#   Installation: Pre-installed, but see file_mime_type notes below
#
# PDF to text conversion:
#   Program: pdftotext
#   Version tested: 3.02
#   Installation: Ubuntu  xpdf-utils package
#   Home page: http://www.foolabs.com/xpdf/
#
# HTML to text conversion:
#   Program: html2text
#   Version tested: 1.3.2a
#   Installation: Ubuntu package
#   Home page: http://userpage.fu-berlin.de/~mbayer/tools/html2text.html
#
# Open Document to text conversion:
#   Program: odt2txt
#   Version tested: 0.3
#   Home page: http://www.freewisdom.org/projects/python-markdown/odt2txt.php
#
# Microsoft Word to text conversion:
#   Program: antiword
#   Version tested: 0.37
#   Installation: Ubuntu antiword package
#   Home page: http://www.winfield.demon.nl/
#
# Microsoft Powerpoint to text conversion:
#   Program: catppt
#   Version tested: Catdoc Version 0.94.2
#   Installation: Ubuntu package
#   Home page: http://www.wagner.pp.ru/~vitus/software/catdoc/

require 'tempfile'

module FerretHelper
  FILE_EXTENSION_MIME_TYPES = {
    '.doc'  => 'application/msword',
    '.dot'  => 'application/msword',
    '.ppt' => 'application/powerpoint',
    '.xls' => 'application/excel',
    '.html' => 'text/html',
    '.htm'  => 'text/html',
    '.odt'  => 'application/vnd.oasis.opendocument.text',
    '.pdf'  => 'application/pdf',
    '.txt'  => 'text/plain',
    '.text'  => 'text/plain',
    '.tex' => 'text/plain',
    '.for' => 'text/plain',
    '.cpp' => 'text/plain',
    '.c'   => 'text/plain',
    '.rb'  => 'text/plain',
    '.ins'  => 'text/plain',
    '.vee'  => 'text/plain',
    '.rtf' => 'application/rtf'
  }
  
  # Infer MIME type from file name (not a safe way to do things).
  def filename_mime_type(filename)
    FILE_EXTENSION_MIME_TYPES[File.extname(filename).downcase] ||
      'application/octet-stream'
  end
  
  def odt_to_text(src, dst)
    %x{odt2txt \"#{src}\" > \"#{dst}\" 2>/dev/null}
    raise 'missing odt2txt.py(1) command' if $?.exitstatus == 127
    raise "failed to convert Open Document text file: #{src}" unless $?.exitstatus == 0
  end
  
  def pdf_to_text(src, dst)
    %x{pdftotext -enc UTF-8 \"#{src}\" \"#{dst}\" 2>/dev/null}
    raise 'missing pdftotext(1) command' if $?.exitstatus == 127
    raise "failed to convert pdf file: #{src}" unless $?.exitstatus == 0
  end
  
  def msword_to_text(src, dst)
    %x{antiword \"#{src}\" > \"#{dst}\" 2>/dev/null}
    raise 'missing antiword(1) command' if $?.exitstatus == 127
    raise "failed to convert Word file: #{src}" unless $?.exitstatus == 0
  end
  
  def html_to_text(src, dst)
    encoding=File.which_encoding_for?(src)
    encoding="iso-8859-15" if encoding.empty?
    %x{html2text -nobs \"#{src}\" | iconv -f #{encoding} -t utf8 >\"#{dst}\" 2>/dev/null}
    raise 'missing html2text(1) command' if $?.exitstatus == 127
    raise "failed to convert HTML file: #{src}" unless $?.exitstatus == 0
  end
  
  def ppt_to_text(src, dst)
    %x{catppt  \"#{src}\" > \"#{dst}\" 2>/dev/null}
    raise 'missing catppt(1) command' if $?.exitstatus == 127
    raise "failed to convert Powerpoint file: #{src}" unless $?.exitstatus == 0
  end
  
  def xls_to_text(src, dst)
    #Keeping only lines with non-num chars
    %x{xls2csv \"#{src}\" 2>/dev/null | grep -i [a-z] | sed -e 's/"//g' -e 's/,*$//' -e 's/,/ /g' > \"#{dst}\"}
    raise 'missing xls2csv(1) command' if $?.exitstatus == 127
    raise "failed to convert Excel file: #{src}" unless $?.exitstatus == 0
  end
  
  def rtf_to_text(src, dst)
    %x{unrtf  \"#{src}\" -t text > \"#{dst}\" 2>/dev/null}
    raise 'missing unrtf(1) command' if $?.exitstatus == 127
    raise "failed to convert RTF file: #{src}" unless $?.exitstatus == 0
  end
  
  def plain_to_utf8_text(src,dst)
    encoding=File.which_encoding_for?(src)
    if encoding.empty? then
       FileUtils.cp src, dst
    else
       %x{iconv -f #{encoding} -t utf8  \"#{src}\" > \"#{dst}\" 2>/dev/null}
    end
    raise 'missing iconv(1) command' if $?.exitstatus == 127
    raise "failed to convert plain text file: #{src}" unless $?.exitstatus == 0    
  end
  
  # Convert file to text file.
  def convert_to_text_file(src, dst, mime_type=nil)
    mime_type = file_mime_type(src) unless mime_type
    FileUtils.rm dst, :force => true
    case mime_type
      when 'text/plain'
      plain_to_utf8_text src, dst
      when 'text/html'
      html_to_text src, dst
      when 'application/pdf'
      pdf_to_text src, dst
      when 'application/msword'
      msword_to_text src, dst
      when 'application/vnd.oasis.opendocument.text'
      odt_to_text src, dst
      when 'application/powerpoint'
      ppt_to_text src, dst
      when 'application/excel'
      xls_to_text src, dst
      when 'application/rtf'
      rtf_to_text src, dst
    else
      raise ArgumentError, "no convertor for #{src} (#{mime_type})"
    end
  end
  
  # Convert file to text string.
  def convert_to_text_string(filename, mime_type=nil)
    mime_type = file_mime_type(filename) unless mime_type
    temp_file = Tempfile.new('ferret_helper')
    begin
      temp_file.close   # So it can be written by external program.
      convert_to_text_file(filename, temp_file.path, mime_type)
      result = File.read(temp_file.path)
    ensure
      temp_file.unlink
    end
    result
  end
end

class File
  def self.which_encoding_for?(src)
    parse_for_charset="grep -o charset=[a-z0-9\\-]* | sed 's/charset=//'"
    if File.extname(src)[0,4]==".htm" then
      enc=%x{head -n20 \"#{src}\" | #{parse_for_charset}}.chomp      
    else
      enc=%x{file -i \"#{src}\"  | #{parse_for_charset}}.chomp
    end
    #iso-8859-15 should be used instead of iso-8859-1, for € char
    enc=="iso-8859-1" ? "iso-8859-15" : enc
  end
end
