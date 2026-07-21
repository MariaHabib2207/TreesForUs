ActiveAdmin.register Family do
ActiveAdmin.register Family do
  permit_params :name, user_ids: []

  # ---------------------------------------------------
  # INDEX
  # ---------------------------------------------------
  index do
    selectable_column
    id_column
    column :name
    column "Members" do |family|
      family.users.count
    end
    column :created_at
    actions
  end

  # ---------------------------------------------------
  # FILTERS
  # ---------------------------------------------------
  filter :name
  filter :created_at

  # ---------------------------------------------------
  # FORM
  # ---------------------------------------------------
  form do |f|
    f.inputs do
      f.input :name

      f.input :users,
              as: :check_boxes,
              collection: User.all,
              label: "Assign Users"
    end

    f.actions
  end

  # ---------------------------------------------------
  # SHOW PAGE
  # ---------------------------------------------------
  show do
    attributes_table do
      row :name
      row :created_at
      row :updated_at
    end

    panel "Family Members" do
      table_for family.users do
        column :id
        column :first_name
        column :last_name
        column :role
        column :email
      end
    end
  end
end
end
