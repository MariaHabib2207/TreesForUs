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
#  index_user_profiles_on_user_id  (user_id)

class UserProfile < ApplicationRecord
  has_one_attached :avatar
  belongs_to :user
  acts_as_paranoid


  after_update :notify_profile_owner_if_manager_edited

  enum :marital_status, {
    single: "single",
    married: "married",
    divorced: "divorced",
    widowed: "widowed"
  }

  def self.marital_status_options
    marital_statuses.keys.map { |status| [ status.humanize, status ] }
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

  private

  def notify_profile_owner_if_manager_edited
    return unless updated_by.present?
    return if updated_by == user_id
    return unless (saved_changes.keys & %w[birth_date gender marital_status occupation address city state zip country phone nationality death_date current_status]).any?

    editor = User.find_by(id: updated_by)
    return unless editor&.family_manager?

    already_notified = user.noticed_notifications
                           .where(read_at: nil)
                           .joins(:event)
                           .where(noticed_events: { type: "ProfileEditedNotifier" })
                           .where("noticed_notifications.created_at > ?", 10.minutes.ago)
                           .exists?
    return if already_notified

    ::ProfileEditedNotifier.with(
      message: "#{editor.full_name} updated your profile.",
      url: Rails.application.routes.url_helpers.user_profile_path(user)
    ).deliver(user)
  end
end
