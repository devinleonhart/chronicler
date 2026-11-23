module TrimmedName
  extend ActiveSupport::Concern

  # The characters that JavaScript's trim removes; String#strip leaves the Unicode ones.
  SPACE = /[\t\n\v\f\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]/
  EDGES = /\A#{SPACE}+|#{SPACE}+\z/

  def self.trim(text)
    text.gsub(EDGES, "")
  end

  included do
    normalizes :name, with: ->(name) { TrimmedName.trim(name) }
    validates :name, presence: true, length: { maximum: 255 }
  end
end
