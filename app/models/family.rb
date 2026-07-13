# == Schema Information
#
# Table name: families
#
#  id         :integer          not null, primary key
#  deleted_at :datetime
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_families_on_deleted_at  (deleted_at)
#
class Family < ApplicationRecord

  has_many :family_memberships, dependent: :destroy
  has_many :users, through: :family_memberships
  acts_as_paranoid

  def self.ransackable_attributes(auth_object = nil)
    %w[id name created_at updated_at]
  end

  def friend_family?
    family_memberships.exists? &&
      family_memberships.all? { |m| m.friend? }
  end

  def self.ransackable_associations(auth_object = nil)
    %w[users family_memberships]
  end
end
  
