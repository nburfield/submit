require 'test_helper'

class SystemMailerTest < ActionMailer::TestCase
  def sample_mail_preview
    SystemMailerTest.sample_email(User.where(name: "Nolan").first)
  end
end
