class Sermon < ActiveRecord::Base
  def Sermon.to_title file_name
    ret = File.basename((file_name.split /_/)[-1], ".txt")

    ret.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2').
        gsub(/([a-z\d])([A-Z])/,'\1 \2')
  end

  def url
    "http://media.thevillagechurch.net/sermons/transcripts/#{filename}"
  end

  #thinking sphinx index generation for fields
  define_index do
    indexes title
    indexes content
    has published_date
  end
end
