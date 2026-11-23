# Assigning member ids (such as group_ids) takes effect on save, after they are
# checked. Rails would write them at once, and raise for unknown ones.
module StagedMembers
  extend ActiveSupport::Concern

  MAX_ID = 2_147_483_647

  # JSON and forms send ids as integers, floats without a fraction, or digits.
  def self.parse_id(value)
    id = case value
         when Integer, /\A\d+\z/ then value.to_i
         when Float then whole(value)
         end
    id if id&.between?(1, MAX_ID)
  end

  def self.whole(float)
    float.to_i if float.finite? && float == float.to_i
  end

  included do
    validate :staged_members_exist
    after_save :write_staged_members
  end

  class_methods do
    def stages_members(association)
      ids = "#{association.to_s.singularize}_ids"

      define_method("#{ids}=") { |values| staged_members[association] = Array(values) }
      define_method(ids) { staged_ids(association) || super() }
    end
  end

  def reload(*)
    staged_members.clear
    super
  end

  private

  def staged_members
    @staged_members ||= {}
  end

  def staged_ids(association)
    staged_members[association]&.filter_map { |value| StagedMembers.parse_id(value) }&.uniq
  end

  def staged_members_exist
    staged_members.each do |association, values|
      known = self.class.reflect_on_association(association).klass.where(id: staged_ids(association)).ids
      unknown = values.reject { |value| known.include?(StagedMembers.parse_id(value)) }
      next if unknown.empty?

      errors.add(association, :unknown, ids: unknown.map { |value| value.nil? ? "null" : value }.join(", "))
    end
  end

  def write_staged_members
    staged_members.each_key do |association|
      # Compare with the stored members, not with ones loaded earlier.
      [self.class.reflect_on_association(association).through_reflection.name, association].each do |name|
        association(name).reset
      end
      association(association).ids_writer(staged_ids(association))
    end
    staged_members.clear
  end
end
