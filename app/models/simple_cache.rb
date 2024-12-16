class SimpleCache < Hash

  class Item
    attr_reader :expiry, :value
    def initialize(expiry, value)
      @expiry, @value = expiry, value
    end
  end

  def initialize(ttl)
    @ttl = ttl
    Rails.logger.info("  SimpleCache: will store items for #{ttl}s")
  end

  def [](key)
    item = super(key)
    if item.nil? or item.expiry <= Time.now
      Rails.logger.info("  SimpleCache: miss on #{key}")
      nil
    else
      Rails.logger.debug("  SimpleCache: hit on #{key}")
      item.value
    end
  end

  def []=(key, value)
    Rails.logger.info("  SimpleCache: store on #{key}")
    super(key, Item.new(@ttl.from_now, value))
    value
  end

end
