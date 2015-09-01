crumb :upload_datum do |upload_datum|
  link upload_datum.name, edit_upload_datum_url(upload_datum)
  course = upload_datum.source.assignment.course
  if upload_datum.test_case.present? and current_user.has_local_role? :grader, course then
    parent :test_case, upload_datum.test_case
  elsif upload_datum.test_case.present? and current_user.has_role? :admin
    parent :test_case, upload_datum.test_case
  else
    parent :submission, upload_datum.submission
  end
end
