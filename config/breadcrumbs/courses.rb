
crumb :courses do
  link "Courses", courses_url
end

crumb :course do |course|
  link course.name, course
  parent :courses
end

crumb :course_users do |course|
  link "Enrolled Users", courses_users_url(course)
  parent :course, course
end

crumb :course_edit do |course|
  link "Edit", edit_course_url(course)
  parent :course, course
end

crumb :course_grades do |course|
  link "Grades", course_all_grades_url(course)
  parent :course, course
end
