module TypoGuid
  def create_guid
    self.guid rescue return true
    return true unless self.guid.blank?

    self.guid = SecureRandom.uuid.to_s
  end
end
