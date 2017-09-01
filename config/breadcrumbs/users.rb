crumb :user_settings do |user|
  link "Settings", settings_url(user)
  parent :root
end

crumb :user_list do |user|
  link "User List", users_url(user)
  parent :root
end

crumb :user_edit do |user|
  link "User Edit", edit_user_path(user)
  parent :user_list, user
end
