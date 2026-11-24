# An id from an address or a tool.
module RecordId
  def self.parse(value, label)
    id = StagedMembers.parse_id(value.to_s[/\A\d+\z/])
    id || raise(Rejection, "Invalid #{label} ID")
  end
end
