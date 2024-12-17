class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Set these in subclasses to permitted attribute lists for creation and
  # update operations. Much of Typo uses a slightly unusual pattern that can
  # assign parameters in "new"/"edit" to populate a form in advance, so the
  # permitted parameter code needed is a bit more complex than usual.
  #
  class_attribute :permitted_params_for_new
  class_attribute :permitted_params_for_edit

  # Call for "new" or "create" operations in controllers. Pass the params, then
  # the key at the top level under which form submission or other parameters
  # are expected to be found (e.g. Comment models -> :comment). Finally pass
  # named parameter 'required' as 'false' for "new" actions, since the form may
  # not have parameters and that's fine, or 'true' for "create" actions, since
  # we definitely expect parameters to be given.
  #
  def self.params_for_create(params, key, required:)
    unpermitted = required ? params.require(key) : params[key]
    permitted   = unpermitted.nil? ? {} : unpermitted.permit(self.permitted_params_for_new)

    return permitted
  end

  # Equivalent of ::params_for_create for "edit" (analogous to "new") and
  # "update" (analogous to "create") actions in controllers.
  #
  def self.params_for_edit(params, key, required:)
    unpermitted = required ? params.require(key) : params[key]
    permitted   = unpermitted.nil? ? {} : unpermitted.permit(self.permitted_params_for_edit)

    return permitted
  end

end
