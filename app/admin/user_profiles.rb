ActiveAdmin.register UserProfile do
  permit_params :user_id,
                :birth_date,
                :death_date,
                :gender,
                :marital_status,
                :occupation,
                :address,
                :city,
                :state,
                :zip,
                :country,
                :phone,
                :nationality,
                :created_by,
                :updated_by,
                :current_status

  index do
    selectable_column
    id_column

    column :user
    column :gender
    column :marital_status
    column :occupation
    column :city
    column :country
    column :phone
    column :current_status

    actions
  end

  filter :gender
  filter :marital_status
  filter :occupation
  filter :city
  filter :country
  filter :current_status

  form do |f|
    f.inputs do
      f.input :user
      f.input :birth_date, as: :datepicker
      f.input :death_date, as: :datepicker
      f.input :gender
      f.input :marital_status
      f.input :occupation
      f.input :address
      f.input :city
      f.input :state
      f.input :zip
      f.input :country
      f.input :phone
      f.input :nationality
      f.input :created_by
      f.input :updated_by
      f.input :current_status
    end

    f.actions
  end
end
