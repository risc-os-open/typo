class RegexPattern < BlacklistPattern
  def matches?(string)
    string.match(/#{pattern}/)
  end

  def to_s
    "Regex /#{pattern}/"
  end
end
