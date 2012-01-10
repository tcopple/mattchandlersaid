class SearchController < ApplicationController
  respond_to :html, :xml, :json, :js

  def index
  end

  def results
    page = params[:page] || 1

    @search = params[:search]

    #update historic query table
    q = Query.find_by_query(@search.downcase)
    if q.nil?
      Query.create(:query => @search.downcase, :count => 1, :last_use => DateTime.now)
    else
      q.update_attributes(:count => q.count+1, :last_use => DateTime.now)
    end

    @results = Sermon.search params[:search], 
		 	     :with => {:published_date => (DateTime.new(2006, 1, 1)..DateTime.now)},
			     :page => page, 
			     :per_page => 10, 
                             :field_weights => { :title => 10, :content => 5}

    respond_with @results
  end

  def recent
    @sermons = Sermon.where("sermons.published_date >= '#{2.months.ago}'").order("sermons.published_date desc")

    respond_with @sermons
  end

  def queries
    @queries = Query.where("queries.last_use >= '#{1.month.ago}'").order("queries.count desc").limit(5)

    respond_with @queries
  end
end
