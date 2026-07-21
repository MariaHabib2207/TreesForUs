# == Schema Information
#
# Table name: user_parent_child_relationships
#
#  id         :integer          not null, primary key
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  child_id   :integer
#  parent_id  :integer
#
# Indexes
#
#  idx_on_parent_id_child_id_94af4b48a2                 (parent_id,child_id) UNIQUE
#  index_user_parent_child_relationships_on_deleted_at  (deleted_at)
#
class UserParentRelationship < ApplicationRecord
  acts_as_paranoid


  self.table_name = "user_parent_child_relationships"

  belongs_to :parent, class_name: "User"
  belongs_to :child, class_name: "User"

  # 1. No duplicate relationships
  validates :child_id, uniqueness: {
    scope: :parent_id,
    message: "already has this parent"
  }

  # Custom validations
  validate :cannot_be_own_parent
  validate :cannot_create_circular_relationship
  validate :parent_limit_validation
  # validate :birth_date_validation

  private

  # ---------------------------
  # 1. Prevent self-parenting
  # ---------------------------
  def cannot_be_own_parent
    if parent_id == child_id
      errors.add(:base, "A user cannot be their own parent")
    end
  end

  # ---------------------------
  # 2. Prevent circular relation
  # ---------------------------
  def cannot_create_circular_relationship
    return if parent.blank? || child.blank?

    if ancestor_ids(parent).include?(child_id)
      errors.add(:base, "This would create a circular relationship")
    end
  end

  def ancestor_ids(user, visited = [])
    return [] if user.blank? || visited.include?(user.id)

    visited << user.id

    user.parents.flat_map do |p|
      [ p.id ] + ancestor_ids(p, visited)
    end
  end

  # ---------------------------
  # 3. Max + Min 2 parents rule
  # ---------------------------
  def parent_limit_validation
    return if child.blank?

    current_count = child.parents.count

    # simulate new record addition
    projected_count = new_record? ? current_count + 1 : current_count

    if projected_count > 2
      errors.add(:child, "cannot have more than 2 parents")
    end

    # NOTE:
    # "at least 2 parents" is usually NOT enforced during creation,
    # because it would block initial inserts.
    #
    # If you REALLY want strict enforcement, uncomment below:
    #
    # if projected_count < 2
    #   errors.add(:child, "must have at least 2 parents")
    # end
  end

  # ---------------------------
  # 4. Birth date validation
  # # ---------------------------
  # def birth_date_validation
  #   return if parent.blank? || child.blank?

  #   return if parent.date_of_birth.blank? || child.date_of_birth.blank?

  #   if parent.date_of_birth >= child.date_of_birth
  #     errors.add(:base, "Parent must be older than child")
  #   end
  # end
end
