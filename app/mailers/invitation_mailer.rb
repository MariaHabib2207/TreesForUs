class InvitationMailer < ApplicationMailer
  def invite(user, raw_token, email, family_code)
    @user           = user
    @family_code    = family_code
    @invitation_url = accept_invitation_url(token: raw_token, family_code: family_code.code)
    mail(to: email, subject: "You've been invited to the family tree — set up your account")
  end
end
