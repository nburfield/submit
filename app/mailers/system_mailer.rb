class SystemMailer < ActionMailer::Base
  default from: "submit@cse.unr.edu"

  def sample_email(user)
    @user = user
    mail(to: @user.email, subject: 'Sample Email')
  end
end
