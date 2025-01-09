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
      content.state = JustPublished.instance if boolean
    end

    def published_at_was_set(content, new_time)
      if new_time.nil?
        return
      elsif new_time <= Time.now
        content.write_attribute(:published_at, nil)
      else
        content.state = PublicationPending.instance
      end
    end

    def draft?
      true
    end
  end
end
