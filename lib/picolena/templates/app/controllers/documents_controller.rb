# Core controller of Picolena search-engine.
# DocumentsController
#  - treats queries
#  - launches searches
#  - returns matching documents
#  - displays document content
#  - displays cached content.

class DocumentsController < ApplicationController
  before_filter :ensure_index_is_created, :except=> :index
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
      pager=::Paginator.new(finder.total_hits, Picolena::ResultsPerPage) do
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

  # Returns the content of the document identified by probably_unique_id, as it is *now*.
  def content
  end

  # Returns the content of the document identified by probably_unique_id, as it was at the time it was indexed.
  # similar to Google cache.
  def cached
    @query=[params[:query],params.delete(:format)].compact.join('.')
  end

  private

  # Returns corresponding document for any given "probably unique id"
  # Redirects to no_valid_link if:
  #  there are more than one matching document (hash collision)
  #  there is no matching document (wrong hash)
  def check_if_valid_link
    @probably_unique_id=params[:id]
    @document=Document.find_by_unique_id(@probably_unique_id) rescue no_valid_link
  end
  
  def ensure_index_is_created
    Indexer.ensure_index_existence
    while Indexer.do_not_disturb_while_indexing do
      sleep 1
    end
  end

  # Flashes a warning and redirects to documents_url.
  def no_valid_link
    flash[:warning]="no valid link"
    redirect_to documents_url
    return false
  end
end
