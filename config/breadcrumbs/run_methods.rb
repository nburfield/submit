crumb :run_method do |run_method|
  link "Run Method", edit_run_method_url(run_method)
  parent :test_case, run_method.test_case
end

crumb :run_method_new do |test_case|
  link "New Run Method"
  parent :test_case, test_case
end
