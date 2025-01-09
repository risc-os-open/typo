module ContentState
  class Factory

    # Pass a leaf name, as a symbol - e.g. :published, :just_withdrawn - rather
    # than a full class name, such as "ContentState::Published". If blank, the
    # 'new' state is used.
    #
    def self.new(state_name)
      return ContentState::New.instance if !state_name || state_name.blank?
      state_name = state_name.to_s.underscore
      unless state_name.rindex('/')
        state_name = 'content_state/' + state_name
      end
      state_name.camelize.constantize.instance
    end
  end
end
