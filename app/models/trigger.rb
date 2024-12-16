class Trigger < ApplicationRecord
  belongs_to :pending_item, :polymorphic => true

  class << self
    def post_action(due_at, item, method='came_due')
      create!(:due_at => due_at, :pending_item => item,
              :trigger_method => method)
      fire
    end

    def fire
      self.where('due_at <= ?', Time.now).destroy_all()
      true
    end

    def remove(pending_item, conditions = { })
      return if pending_item.new_record?
      conditions_string =
        conditions.keys.collect{ |k| "(#{k} = :#{k})"}.join(' AND ')

      self
        .where(conditions_string, conditions)
        .where('pending_item_id = ? AND pending_item_type = ?', pending_item.id, pending_item.class.to_s)
        .delete_all
    end
  end

  def before_destroy
    pending_item.send(trigger_method)
    true
  end
end
