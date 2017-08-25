crumb :assignment do |assignment|
  link assignment.name, assignment
  parent :course, assignment.course
end

crumb :assignment_edit do |assignment|
  link "Edit", assignment
  parent :assignment, assignment
end

crumb :assignment_grades do |assignment|
  link "Grades", assignment
  parent :assignment, assignment
end

crumb :assignment_new do |course|
  link "New Assignment", select_assignment_url
  parent :course, course
end

crumb :assignment_copy do |course|
  link "Import Assignment", select_assignment_url
  parent :course, course
end
