class SearchController < ApplicationController
  respond_to :html, :xml, :json, :js

  def index
  end

  def results
    page = params[:page] || 1
    @search = params[:search]
    @results = Sermon.search params[:search], :page => page, :per_page => 10, :field_weights => { :title => 10, :content => 5}
    @total_sermons = Sermon.all.count

    respond_with @results
  end
end
