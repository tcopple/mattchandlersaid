class SearchController < ApplicationController
  respond_to :html, :xml, :json, :js

  def index
  end

  def results
    page = params[:page] || 1
    @results = Sermon.search params[:search], :page => page, :per_page => 10

    respond_with @results
  end
end
