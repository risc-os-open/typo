module ContentState
  class Draft < Base
    include Singleton

    def enter_hook(content)
      super
      content[:published] = false
      content[:published_at] = nil
    end

    def change_published_state(content, boolean)
      content[:published] = boolean
      if boolean
        content.state = JustPublished.instance
      end
    end

    def set_published_at(content, new_time)
      return if new_time.blank?

      if new_time > Time.now
        content.state = PublicationPending.instance
      end
    end

    def draft?
      true
    end
  end
end
