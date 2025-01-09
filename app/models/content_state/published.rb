module ContentState
  class Published < Base
    include Singleton

    def published?(content)
      true
    end

    def enter_hook(content)
      super
      content[:published] = true
      content[:published_at] ||= Time.now
    end

    def change_published_state(content, boolean)
      if ! boolean
        content[:published] = false
        content[:published_at] = nil
        content.state = Factory.new(:just_withdrawn)
      end
    end

    def withdraw(content)
      content.state = Factory.new(:just_withdrawn)
    end

    def published_at_was_set(content, new_time)
      if new_time.nil?
        return
      elsif new_time > Time.now
        content.state = PublicationPending.instance
      end
    end
  end
end
