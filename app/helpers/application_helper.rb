module ApplicationHelper
  def google_font_link_tag family
    tag 'link', {:rel => :stylesheet, :type => Mime::CSS, :href => "http://fonts.googleapis.com/css?family=#{family}"}, false, false
  end

  def google_analytics
    <<-END_SQL
      <script type="text/javascript">

      var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-26223301-1']);
      _gaq.push(['_trackPageview']);

      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();

      </script>
    END_SQL
  end
end
