class SettingsController < ApplicationController
  before_action :authenticate_user!

  def privacy
    @family_members = current_user.family_members
  end

  def update_privacy
    if User::PROFILE_VISIBILITY_MODES.include?(params[:profile_visibility])
      current_user.update_column(:profile_visibility, params[:profile_visibility])
    end

    %i[last_seen online avatar].each do |setting|
      mode = params.dig(:visibility, setting)
      next unless User::VISIBILITY_MODES.include?(mode)

      current_user.update_column("#{setting}_visibility", mode)

      if mode == "custom"
        viewer_ids = Array(params.dig(:custom_viewers, setting))
        current_user.set_custom_viewers(setting, viewer_ids)
      end
    end

    respond_to do |format|
      format.html { redirect_to authenticated_root_path, notice: "Privacy settings updated. You may need to sign out and back in to see the changes." }
      format.json { render json: { status: "ok" } }
    end
  end
end