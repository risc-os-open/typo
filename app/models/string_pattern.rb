class StringPattern < BlacklistPattern
  def matches?(string)
    string.match(/\b#{Regexp.quote(pattern)}\b/)
  end

  def to_s
    "String '#{pattern}'"
  end
end
