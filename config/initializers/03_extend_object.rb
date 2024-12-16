class Object
  def to_text_filter
    TextFilter.find_by(name: self.to_s) || TextFilter.find_by(name: 'none')
  end
end
