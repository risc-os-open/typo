class RedirectController < ContentController
  def redirect
    r = Redirect.find_by(from_path: params[:from])

    if r
      path     = r.to_path
      url_root = Rails.application.config.relative_url_root
      path = url_root + path unless url_root.blank? || path[0, url_root.length] == url_root

      redirect_to path, status: 301
    else
      render plain: "Page not found", status: 404
    end
  end
end
