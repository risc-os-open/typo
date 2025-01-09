module ContentState
  class Withdrawn < Base
    include Singleton

    def enter_hook(content)
      content[:published] = false
    end

    def change_published_state(content, boolean)
      return unless boolean
      content[:published] = true
      content.state = Published.instance
    end

    def published_at_was_set(content, new_time)
      Trigger.remove(content, trigger_method: 'publish!')

      if new_time.nil?
        return
      elsif new_time <= Time.now
        content.state = PublicationPending.instance
      end
    end

    def withdrawn?
      true
    end
  end
end
