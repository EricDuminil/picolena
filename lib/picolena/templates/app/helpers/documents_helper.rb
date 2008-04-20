module DocumentsHelper
  # Returns true if no document as been found for a given query.
  def nothing_found?
    @matching_documents.nil? or @matching_documents.entries.empty?
  end
  
  # Very basic pagination.
  # Provides liks to Next, Prev and FirstPage when needed.
  def should_paginate(page,query)
    [(link_to("&larr;&larr;", :action => :show, :id => query, :page => 1) if page.number>2),
     (link_to("&larr;", :action => :show, :id => query, :page => page.prev.number) if page.prev?),
     (link_to("&rarr;", :action => :show, :id => query, :page => page.next.number) if page.next?)].compact.join(" | ")
  end
  
  # Returns a localized sentence like "Results 1-10 of 12 for Zimbabwe (0.472s)" or
  # "Résultats 1-2 parmi 2 pour whatever (0.012s)"
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
  
  # Returns the time needed to treat the query and launch the search, with a ms precision : (0.472s)
  def show_time_needed(dt)
    content_tag(:small,'('<<number_with_precision(dt,3)<<'s)')
  end
  
  # When possible, highlights content of the document that matches the query.
  def highlight_matching_content(document)
    content_tag(:ul,document.matching_content.collect{|sentence|
      content_tag(:li,h(sentence).gsub(/&lt;&lt;(.*?)&gt;&gt;/,'<strong>\1</strong>').gsub(/\v|\f/,''))
    }) if document.matching_content
  end
  
  # Returns icon and filename for any given document.
  def icon_and_filename_for(document)
    [icon_for(document.extname),document.filename].join("&nbsp;")
  end
  
  # Returns the location (if avaible) of the filetype icon.
  def icon_for(filetype)    
    icon_symbol=FiletypeToIconSymbol[filetype.downcase.sub(/^\./,'')]
    image_tag("icons/#{icon_symbol}.png") if icon_symbol
  end
  
  # Returns a link to a backup search engine that could maybe find more results for the same query.
  def link_to_backup_search_engine(query)
    link_to :backup_search_engine_name.l, :backup_search_engine_url.l<<query
  end
  
  # For any indexed document, returns a link to its containing directory.
  def link_to_containing_directory(document)
    link_name=image_tag('icons/remote_folder.png')<<'&nbsp;'<<content_tag(:small,document.alias_path)
    link_to link_name, document.alias_path, :target=>'_blank'
  end
  
  # For any indexed document, returns a link to show its content.
  def link_to_plain_text_content(document)
    link_name=image_tag('icons/plain_text_small.png')<<'&nbsp;'<<content_tag(:small,:text_content.l)
    link_to link_name, content_document_path(document.probably_unique_id)
  end

  # For any indexed document, returns a link to show its cached content.
  def link_to_cached_content(document)
    link_name="("<<content_tag(:small,:cached.l)<<")"
    link_to link_name, cached_document_path(document.probably_unique_id)
  end
end
