class Redirect < ApplicationRecord
  validates_uniqueness_of :from_path
end
