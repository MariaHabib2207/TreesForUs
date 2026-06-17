# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController

  before_action :configure_permitted_parameters, if: :devise_controller?

  def new
    build_resource({})
    resource.build_user_profile
    respond_with resource
  end

  def create
    build_resource(sign_up_params)

    ActiveRecord::Base.transaction do
      resource.save!

      # ── Family code path ──────────────────────────────────────────
      if params[:family_code].present?
        fc = FamilyCode.valid.find_by(code: params[:family_code].upcase.strip)
        raise ActiveRecord::RecordInvalid.new(FamilyCode.new), "Invalid or expired family code." unless fc

        FamilyMembership.create!(
          user:            resource,
          family:          fc.family,
          membership_type: fc.membership_type
        )

        fc.mark_used!(resource)

      # ── Manual family select path ─────────────────────────────────
      else
        family =
          if params[:new_family_name].present?
            Family.create!(name: params[:new_family_name])
          else
            Family.find_by(id: params[:family_id])
          end

        if family.present?
          pending = if params[:new_family_name].blank? && params[:family_id].present?
            mem_type = params[:membership_type].to_s.downcase
            if mem_type.include?("birth")
              "select_parent"
            elsif mem_type.include?("marriage")
              "select_spouse"
            end
          end

          FamilyMembership.create!(
            user:            resource,
            family:          family,
            membership_type: params[:membership_type],
            pending_link:    pending
          )
        end
      end
    end

    if resource.persisted?

      if resource.active_for_authentication?
        flash[:notice] = "Welcome! Your account has been created successfully."
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)

      else
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end

    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    clean_up_passwords resource
    set_minimum_password_length
    render :new, status: :unprocessable_entity
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name,
      :last_name,
      :identification_type,
      :identification_number,
      :family_id,
      :new_family_name,
      :membership_type,
      :family_code,          
      user_profile_attributes: [
        :birth_date,
        :marital_status
      ]
    ])

    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name,
      :last_name,
      :identification_type,
      :identification_number,
      user_profile_attributes: [
        :birth_date,
        :marital_status
      ]
    ])
  end

end