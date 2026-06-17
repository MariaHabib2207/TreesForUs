# app/mailers/family_code_mailer.rb
class FamilyCodeMailer < ApplicationMailer
  def invite(family_code)
    @family_code = family_code
    @family      = family_code.family
    @manager     = family_code.created_by
    @expires_at  = family_code.expires_at.strftime("%d %b %Y, %I:%M %p")
    @register_url = new_user_registration_url(family_code: family_code.code)

    mail(
      to:      family_code.email,
      subject: "You've been invited to join #{@family.name} on Tree Of Us"
    )
  end
end