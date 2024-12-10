module XmlHelper
  def pub_date(time)
    time.rfc822
  end

  def post_title(post)
    h(post.title)
  end

  def blog_title
    this_blog.blog_name || "Unnamed blog"
  end

  def collection_lastmod(collection)
    article_updated = collection.articles.order(updated_at: :desc).first
    article_published = collection.articles.order(published_at: :desc).first

    times = []
    times.push article_updated.updated_at if article_updated
    times.push article_published.updated_at if article_published

    if times.empty?
      Time.at(0).xmlschema
    else
      times.max.xmlschema
    end
  end
end
