# == Schema Information
#
# Table name: user_profiles
#
#  id             :integer          not null, primary key
#  address        :string
#  birth_date     :date
#  city           :string
#  country        :string
#  created_by     :integer
#  current_status :string
#  gender         :string
#  marital_status :string
#  nationality    :string
#  occupation     :string
#  phone          :string
#  state          :string
#  updated_by     :integer
#  zip            :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :integer          not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
#  index_user_profiles_on_user_id  (user_id)

class UserProfile < ApplicationRecord
  has_one_attached :avatar
  belongs_to :user


  enum :marital_status, {
    single: "single",
    married: "married",
    divorced: "divorced",
    widowed: "widowed"
  }

    def self.marital_status_options
    marital_statuses.keys.map { |status| [status.humanize, status] }
  end

  def self.ransackable_attributes(auth_object = nil)
  [
    "id",
    "user_id",
    "birth_date",
    "gender",
    "marital_status",
    "occupation",
    "address",
    "city",
    "state",
    "zip",
    "country",
    "phone",
    "nationality",
    "created_by",
    "updated_by",
    "current_status",
    "created_at",
    "updated_at"
  ]
end
end
