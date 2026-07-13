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
require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
