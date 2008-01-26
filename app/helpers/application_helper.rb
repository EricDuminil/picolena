# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def nothing_found?
    @matching_documents.nil? or @matching_documents.entries.empty?
  end
end