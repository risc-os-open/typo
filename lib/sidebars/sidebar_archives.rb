class Sidebars::SidebarArchives < Sidebar
  description 'Displays links to monthly archives'
  setting :show_count, true, :label => 'Show article counts', :input_type => :checkbox
  setting :count,      10,   :label => 'Number of Months'

  attr_accessor :archives

  def parse_request(contents, params)
    date_func = "extract(year from published_at) as year,extract(month from published_at) as month"
    article_counts = Content.find_by_sql(["select count(*) as count, #{date_func} from contents where type='Article' and published = ? and published_at < ? group by year,month order by year desc,month desc limit ? ",true,Time.now,count.to_i])

    @archives = article_counts.map do |entry|
      {
        :name => "#{Date::MONTHNAMES[entry.month.to_i]} #{entry.year}",
        :month => entry.month.to_i,
        :year => entry.year.to_i,
        :article_count => entry.count
      }
    end
  end
end
