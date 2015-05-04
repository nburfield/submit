crumb :upload_datum do |upload_datum|
  link upload_datum.name, edit_upload_datum_url(upload_datum)
  if upload_datum.test_case.present? then
    parent :test_case, upload_datum.test_case
  else
    parent :submission, upload_datum.submission
  end
end
