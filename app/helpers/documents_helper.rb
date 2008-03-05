module DocumentsHelper
  def should_paginate(page,query)
      [(link_to("&larr;&larr;", :action => :show, :id => query, :page => 1) if page.number>2),
      (link_to("&larr;", :action => :show, :id => query, :page => page.prev.number) if page.prev?),
      (link_to("&rarr;", :action => :show, :id => query, :page => page.next.number) if page.next?)].compact.join(" | ")
  end
  
  def describe_results(page, total_hits, dt, query)
    [:results.l,
    content_tag(:strong,"#{page.first_item_number}-#{page.last_item_number}"),
    :of.l,
    content_tag(:strong,total_hits),
    :for.l,
    content_tag(:strong,query),
    show_time_needed(dt)
    ].join(' ')
  end
  
  def show_time_needed(dt)
    content_tag(:small,'('<<number_with_precision(dt,3)<<'s)')
  end

  def highlight_matching_content(document)
    content_tag(:ul,document.matching_content.collect{|sentence|
      content_tag(:li,sentence.gsub(/<<(.*?)>>/,'<strong>\1</strong>').gsub(/\v|\f/,''))
    }) if document.matching_content
  end
  
  def icon_and_filename_for(result)
    [icon_for(result.extname),result.filename].join("&nbsp;")
  end
  
  def icon_for(filetype)    
    pic_for_exts={
      :xls=>%w{xls xlsx},
      :doc=>%w{doc odt rtf dot docx},
      :pdf=>%w{pdf},
      :txt=>%w{txt text tex bib log ini},
      :ogg=>%w{mp3 ogg wma wav wmv tee},
      :html=>%w{html htm},
      :ppt=>%w{ppt pps pptx},
      :package=>%w{gz rar zip bak},
      :picture=>%w{psd jpg png gif eps bmp ico},
      :cad=>%w{dwg dxf},
      :exe=>%w{exe dll},
      :video=>%w{avi wmv mpg mpeg},
      :code=>%w{for cpp c rb},
      :insel=>%w{ins vee}
    }
    pic=pic_for_exts.find{|pic, extensions|
      extensions.any? { |ext| filetype.sub(/\./,'').downcase==ext}
    }
    image_tag("icons/#{pic.first}.png") if pic
  end
  
  def google?(query)
    link_to "Google?", "http://www.google.de/search?q=#{query}"
  end
  
  def link_to_containing_directory(result)
    link_name=image_tag('icons/remote_folder.png')<<content_tag(:small,result.alias_path)
    link_to link_name, result.alias_path, :target=>'_blank'
  end
end