require 'strscan'

module Syntax

  # A single token extracted by a tokenizer. It is simply the lexeme
  # itself, decorated with a 'group' attribute to identify the type of the
  # lexeme.
  class Token < String

    # the type of the lexeme that was extracted.
    attr_reader :group

    # the instruction associated with this token (:none, :region_open, or
    # :region_close)
    attr_reader :instruction

    # Create a new Token representing the given text, and belonging to the
    # given group.
    def initialize( text, group, instruction = :none )
      super text
      @group = group
      @instruction = instruction
    end

  end

end
