ActiveAdmin.register User do
  permit_params :email,
                :first_name,
                :last_name,
                :role,
                :password,
                :password_confirmation,
                :identification_type,
                :identification_number,
                :new_family_name,
                family_ids: []
  filter :email
  filter :first_name
  filter :last_name
  filter :role
  filter :status

  form do |f|
    f.inputs do
      f.input :email
      f.input :first_name
      f.input :last_name

      f.input :role,
              as: :select,
              collection: User.roles.keys,
              input_html: { id: "user_role_select" }

      f.input :identification_type,
              as: :select,
              collection: User.identification_types.keys

      f.input :identification_number

      # ---------------------------------------------------
      # EXISTING FAMILIES
      # ---------------------------------------------------
      f.input :family_ids,
              as: :check_boxes,
              collection: Family.all,
              label: "Select Existing Families"

      # ---------------------------------------------------
      # NEW FAMILY (ONLY MANAGER)
      # ---------------------------------------------------
      if f.object.family_manager?
        f.input :new_family_name, label: "Create New Family"
      end

      f.input :password
      f.input :password_confirmation
    end

    f.actions
  end

controller do
  def create
    user = User.new(permitted_params[:user])

    if user.save
      handle_families(user)
      redirect_to admin_user_path(user)
    else
      render :new
    end
  end

  private

  def handle_families(user)
    # ---------------------------------------------------
    # NEW FAMILY (ONLY MANAGER)
    # ---------------------------------------------------
    if user.family_manager? && params[:user][:new_family_name].present?
      family = Family.create!(name: params[:user][:new_family_name])

      FamilyMembership.create!(
        user: user,
        family: family,
        membership_type: 1
      )
    end

    # ---------------------------------------------------
    # EXISTING FAMILIES
    # ---------------------------------------------------
    Array(params[:user][:family_ids]).reject(&:blank?).each do |family_id|
      FamilyMembership.find_or_create_by!(
        user: user,
        family_id: family_id,
        membership_type: user.family_manager? ? 1 : 0
      )
    end
  end
end
end
