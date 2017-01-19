Rails.application.routes.draw do
  resources :user_sessions

  get 'login' => "user_sessions#new",      :as => :login
  get 'logout' => "user_sessions#destroy", :as => :logout

  resources :users

  get 'dashboard' => 'users#dashboard', :as => :dashboard
  get 'settings' => 'users#settings', :as => :settings
  patch 'settings' => 'users#update', :as => :setting
  get 'signup' => 'users#new', :as => :signup

  post 'courses/enroll' => 'courses#join'
  get 'courses/:id/users' => 'courses#users', :as => :courses_users
  get '/courses/:id/users/:user_id' => 'courses#edit_user', :as => :course_user_edit
  patch '/courses/:id/users/:user_id' => 'courses#update_user'
  get 'course/:id/users/:user_id/kick' => 'courses#kick_user', :as => :course_user_kick
  get 'course/all_grades/:id' => 'courses#view_grades', :as => :course_all_grades
  post 'course/all_grades/:id' => 'courses#download_grades'
  resources :courses

  get 'assignments/new/:course_id' => 'assignments#new', :as => :new_assignment
  post 'assignments/new/:course_id' => 'assignments#create'
  get 'assignments/copy/:course_id' => 'assignments#copy', :as => :select_assignment
  post 'assignments/copy/:course_id/old_assignment/:old_assignment_id' => 'assignments#copy_create', :as => :copy_assignment
  get 'assignments/grade_all/:id' => 'assignments#grade_all', :as => :grade_all_assignment
  get 'assignments/all_grades/:id' => 'assignments#all_grades', :as => :view_all_grades_assignments
  get 'assignments/unsubmit_all_assignmets/:id' => 'assignments#unsubmit_all_assignments', :as => :unsubmit_all_assignments
  post 'assignments/all_grades/:id' => 'assignments#download_grades'
  resources :assignments

  delete 'submissions/outputs/:id' => 'submissions#delete_outputs', :as => :delete_outputs
  get 'submissions/outputs/:id' => 'submissions#run_save_update', :as => :run_save_update
  get 'submissions/data/:id' => 'submissions#get_data', :as => :get_data
  get 'submissions/run_program/:id' => 'submissions#run', :as => :run_submission
  post 'submissions/submit_submission/:id' => 'submissions#submit', :as => :submit_submission
  post 'submissions/unsubmit_submission/:id' => 'submissions#unsubmit', :as => :unsubmit_submission
  resources :submissions

  post '/upload_data/:type/:destination_id' => 'upload_data#create', :as => :create_file
  post '/upload_data/blank/:type/:destination_id' => 'upload_data#create_blank', :as => :create_blank_file
  post '/upload_data/:id/' => 'upload_data#download_file', :as => :download_file
  post '/upload_data/zip/:type/:destination_id' => 'upload_data#download_zip', :as => :download_zip
  resources :upload_data

  get 'test_cases/create_output/:id' => 'test_cases#create_output'  
  resources :test_cases

  get '/inputs/new/:run_method_id' => 'inputs#new', :as => :new_input
  post '/inputs/new/:run_method_id' => 'inputs#create'
  resources :inputs

  get '/run_methods/new/:test_case_id' => 'run_methods#new', :as => :new_run_method
  post '/run_methods/new/:test_case_id' => 'run_methods#create'
  resources :run_methods
  
  post '/comments/new/:upload_id' => 'comments#create', :as => :create_comment
  resources :comments

  post 'api_submission/run_program/:id' => 'api_submission#data'
  post 'api_submission/create_output/:id' => 'api_submission#output'
  
  
  root :to => 'user_sessions#new'
end
