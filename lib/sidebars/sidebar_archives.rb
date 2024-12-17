class Sidebars::SidebarArchives < Sidebar
  description 'Displays links to monthly archives'

  setting :show_count, true, label: 'Show article counts', input_type: :checkbox
  setting :count,      10,   label: 'Number of Months'

  attr_accessor :archives

  def parse_request(contents, params)
    article_counts = Content
      .select('COUNT(*) AS count, EXTRACT(year FROM published_at) AS year, EXTRACT(month FROM published_at) AS month')
      .where(type: 'Article', published: true)
      .where('published_at < ?', Time.now)
      .group('year, month')
      .order('year DESC, month DESC')
      .limit(count.to_i)

    @archives = article_counts.map do |entry|
      month = entry.month.to_i
      year  = entry.year.to_i
      count = entry.count.to_i

      {
        name:          "#{Date::MONTHNAMES[month]} #{year}",
        month:         month,
        year:          year,
        article_count: count
      }
    end
  end
end
