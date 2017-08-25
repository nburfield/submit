crumb :submission do |submission|
  if current_user.has_local_role? :student, submission.assignment.course
    link submission.user.first_name, submission
    parent :course, submission.assignment.course
  else
    link submission.user.first_name, submission
    parent :assignment, submission.assignment
  end
end

crumb :submission_run do |submission|
  link "Test Run"
  parent :submission, submission
end
