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
#  death_date     :date
#  deleted_at     :datetime
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
#  index_user_profiles_on_deleted_at  (deleted_at)
#  index_user_profiles_on_user_id     (user_id)
#
require "test_helper"

class UserProfileTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
