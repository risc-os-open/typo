class PageCache < ApplicationRecord
  cattr_accessor :public_path
  @@public_path = ActionController::Base.page_cache_directory

  def self.sweep(pattern)
    self.where('name LIKE ?', pattern).destroy_all()
  end

  def self.sweep_all
    self.destroy_all()
  end

  private

  after_destroy :expire_cache

  def expire_cache
    # It'd be better to call expire_page here, except it's a
    # controller method and we can't get to it.
    path = PageCache.public_path + "/#{self.name}"

    logger.info "Sweeping #{self.name}"
    delete_file(path)
  end

  def delete_file(path)
    File.delete(path) if File.file?(path)
  end
end
