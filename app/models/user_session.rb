class UserSession < Authlogic::Session::Base
  verify_password_method :valid_ldap_credentials?
  remember_me(true)
  remember_me_for(60)
end
