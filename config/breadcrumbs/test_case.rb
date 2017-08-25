crumb :test_case do |test_case|
  link "Test Case", test_case
  parent :assignment, test_case.assignment
end
