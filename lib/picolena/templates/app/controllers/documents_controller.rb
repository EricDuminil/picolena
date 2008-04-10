class DocumentsController < ApplicationController  
  before_filter :check_if_valid_link, :only=> [:download, :content, :cached]
  
  # Actually doesn't check anything at all. Just a redirect to show_document(query)
  #
  # FIXME: remove this useless action, and go directly from submit button to GET :action => show
  def check_query
    redirect_to :action=>'show', :id=>params[:query]
  end
  
  
  # Show the matching documents for a given query
  def show
    start=Time.now
      @query=[params[:id],params.delete(:format)].compact.join('.')
      page=params[:page]||1
      finder=Finder.new(@query,page)
      finder.execute!
      pager=::Paginator.new(finder.total_hits, ResultsPerPage) do
        finder.matching_documents
      end
      @matching_documents=pager.page(page)
      @total_hits=finder.total_hits
    @time_needed=Time.now-start
  end
  
  
  # Download the file whose probably_unique_id is given.
  # If the checksum is incorrect, redirect to documents_url via no_valid_link
  def download
    send_file @document.complete_path
  end
  
  def content
  end
  
  def cached
  end
  
  private
  
  def check_if_valid_link
    @probably_unique_id=params[:id]
    @document=Document.find_by_unique_id(@probably_unique_id) rescue no_valid_link
  end
  
  def no_valid_link
    flash[:warning]="no valid link"
    redirect_to documents_url
    return false
  end
end
