class RecentCommentsSidebar::RecentCommentsSidebar < Sidebar
  description "Displays the most recent comments."

  setting :title,          'Recent Comments', label: 'Title'
  setting :count,          5,                 label: 'Number of Comments'
  setting :show_username,  true,              label: 'Show Username',      input_type: :checkbox
  setting :show_article,   true,              label: 'Show Article Title', input_type: :checkbox

  def comments
    @comments ||= Comments.where(published: true).order(created_at: :desc).limit(count)
  end
end

RecentCommentsSidebar::RecentCommentsSidebar.view_root = File.dirname(__FILE__) + '/views'
