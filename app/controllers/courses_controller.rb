class CoursesController < ApplicationController
  include CoursesHelper

  before_filter :require_user
  before_filter :require_student, :only => [:enrolled]
  before_filter :require_enrolled, :only => [:show]
  before_filter :require_instructor_owner, :only => [:edit, :edit_user, :users, :update, :update_user, :destroy]
  before_filter :require_instructor, :only => [:new, :create]
  
  # Creates the form for creating a new course.
  def new
    @course = Course.new
  end

  # Creates a new course.
  # Redirects to the course's show page on success.
  def create
    @course = Course.new(course_params)

    if @course.save
      @course.generate_join_token
      if current_user.has_role? :instructor
        current_user.courses << @course
        current_user.add_role :instructor, @course
        current_user.add_role :grader, @course
      end

      flash[:notice] = "Course created successfully."
      redirect_to @course
    else
      render :action => :new
    end
  end

  # Displays basic information about the course.
  def show
    @user = current_user
    @course = Course.find(params[:id])

    # Only give students the available assignments
    if current_user.has_local_role? :student, @course
      @assignments = @course.assignments.select { |assignment| Time.now > assignment.start_date }
    else
      @assignments = @course.assignments
    end

    if current_user.has_local_role? :grader, @course or current_user.has_role? :admin
      render "courses/manage" 
    end
  end

  # Displays a list of all courses in the application.
  def index
    if current_user.has_role? :admin
      @courses = Course.all
      render and return
    elsif current_user.has_role? :instructor
      @user = current_user
      @courses = current_user.courses.select { |course| current_user.has_local_role? :instructor, course }
      render "courses/taught" and return
    else
      @courses = current_user.courses
      render "courses/enrolled" and return
    end
  end

  # Creates the form for editing an existing course.
  def edit
    @course = Course.find(params[:id])
  end

  # Applies changes to a course when it is edited.
  def update
    @course = Course.find(params[:id])

    if @course.update_attributes(course_params)
      flash[:notice] = "Course updated!"
      redirect_to course_url(@course)
    else
      render :action => :edit
    end
  end

  # Creates a link between a user and the course.
  # Applies the default student role to the user.
  def join
    course = Course.where(join_token: params[:course][:join_token]).first

    if course and not current_user.courses.include? course
      current_user.courses << course
      current_user.add_role :student, course
      course.assignments.each { |assignment| assignment.create_submissions_for_students }

      flash[:notice] = "Successfully joined class"
      redirect_to course_path(course.id)
    else
      flash[:notice] = "Failed to join class"
      redirect_to :back
    end
  end

  # View all the grades
  def view_grades
    @course = Course.find(params[:id])
  end

  # Download All the students grades from all assignments
  def download_grades
    @course = Course.find(params[:id])
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet :name => 'All Student Grades'

    fmt = Spreadsheet::Format.new :number_format => '0.0'
    sheet.column(2).default_format = fmt

    head = Spreadsheet::Format.new :weight => :bold, :size => 24, :horizontal_align => :center, :vertical_align => :middle
    sheet.merge_cells(0,0,2,2)
    sheet.row(0).default_format = head
    sheet.row(0).push @course.name + " Grades"

    top = Spreadsheet::Format.new :weight => :bold, :size => 18, :horizontal_align => :center
    sheet.row(3).default_format = top
    sheet.row(3).push "First Name", "Last Name"

    row = 4
    @course.users.each do |name|
      if not name.has_local_role? :grader, @course
        sheet.row(row).push name.first_name, name.last_name
        row += 1
      end
    end

    col = 2
    @course.assignments.each do |assignment|
      sheet.row(3).push assignment.name
      sheet.column(col).width = 15
      row = 4
      @course.users.each do |name|
        if not name.has_local_role? :grader, @course
          submission = assignment.submissions.select { |s| s.user == name }.first
          sheet.row(row).push submission.grade
          row += 1
        end
      end
      col += 1
    end

    sheet.column(0).width = 30
    sheet.column(1).width = 30

    blob = StringIO.new
    book.write blob
    send_data blob.string, :filename => @course.name + "_grades.xls", :type => "application/xls"
  end

  # List all users in a specific course.
  def users
    @course = Course.find(params[:id])
    @users = @course.users.all
  end

  # Creates the form for editing a user in the scope of a course.
  def edit_user
    @course = Course.find(params[:id])
    @user = User.find(params[:user_id])
  end

  # Applies changes to a user in the scope of a specific course.
  def update_user
    @course = Course.find(params[:id])
    @user = User.find(params[:user_id])

    User::ROLES.each do |role|
      if params[:user][:roles].include? role
        @user.add_role role, @course
      else
        @user.remove_role role, @course
      end
    end

    flash[:notice] = "User has been updated."
    redirect_to courses_users_url(@course)
  end

  # Kicks a user out of a course.
  def kick_user
    @course = Course.find(params[:id])
    @user = User.find(params[:user_id])

    User::ROLES.each { |role| @user.remove_role role, @course }
    @course.users.delete(@user)

    flash[:notice] = "User has been removed from the course."
    redirect_to :back
  end

  # Deletes a course.
  # Removes all roles in the scope of the course from any enrolled users.
  def destroy
    course = Course.find(params[:id])

    course.users.each do |user|
      User::ROLES.each do |role|
        user.remove_role role, course
      end
    end
    course.destroy

    flash[:notice] = "Course successfully deleted"
    redirect_to courses_url
  end

  private
  def course_params
    params.require(:course).permit(:name, :description, :term, :year, :open, :join_token)
  end

  def require_admin
    if not current_user.has_role? :admin
      flash[:notice] = "That action is only available to admins"
      redirect_to courses_url
    end
  end

  def require_instructor
    return if current_user.has_role? :admin
    
    if not current_user.has_role? :instructor
      flash[:notice] = "That action is only available to instructors"
      redirect_to courses_url
    end
  end

  def require_instructor_owner
    return if current_user.has_role? :admin

    course = Course.find(params[:id])
    if not current_user.has_role? :grader, course
      flash[:notice] = "That action is only available to the instructor of the course"
      redirect_to courses_url
    end
  end

  def require_student
    return if current_user.has_role? :admin

    if not current_user.has_role? :student
      flash[:notice] = "That action is only available to students"
      redirect_to courses_url
    end
  end

  def require_student_enrolled
    return if current_user.has_role? :admin

    course = Course.find(params[:id])
    if not current_user.has_local_role? :student, course
      flash[:notice] = "That action is only available to students enrolled in the course"
      redirect_to courses_url
    end
  end

  def require_enrolled
    return if current_user.has_role? :admin

    course = Course.find(params[:id])
    if not current_user.courses.include? course
      flash[:notice] = "That action is only available to users enrolled in the course"
      redirect_to courses_url
    end
  end
end

