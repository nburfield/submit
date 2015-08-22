class AssignmentsController < ApplicationController
  include AssignmentsHelper

  before_filter :require_user
  before_filter :require_instructor_owner, :only => [:new, :edit, :create, :copy, :destroy, :grade_all, :all_grades, :download_grades, :copy_create]
  before_filter :require_enrolled, :only => [:show]

  # Creates the form to make a new assignment
  def new
    @assignment = Assignment.new
    @course = Course.find(params[:course_id])
  end

  # Creates a new assignment. Redirects to the course page the assignment belongs to on success.
  def create
    @course = Course.find(params[:course_id])

    convert_dates_to_utc
    @assignment = @course.assignments.new(assignment_params)
    if @assignment.save
      @assignment.create_submissions_for_students
      @assignment.create_test_case
      redirect_to course_path(@course)
    else
      render :action => :new
    end
  end

  # Copys over an old assignment
  def copy
    @course = Course.find(params[:course_id])
  end

  # Saves the selected assignment to copy over
  def copy_create
    assignment_old = Assignment.find(params[:old_assignment_id])
    course = Course.find(params[:course_id])
    assignment = course.assignments.new
    assignment.copy(assignment_old)

    if assignment.save
      @test = assignment.test_case
      @old_test = assignment_old.test_case
      copy_files
      redirect_to edit_assignment_path(assignment)
    else
      flash[:notice] = "Could not copy Assignment"
      redirect_to :back
    end
  end

  # Displays an assignment
  def show
    @assignment = Assignment.find(params[:id])
    @course = @assignment.course
    if current_user.has_local_role? :grader, @course or current_user.has_role? :admin
      @submissions = @assignment.submissions
      @test_case = @assignment.test_case 
      render "assignments/manage"
    else
      @submission = @assignment.submissions.select { |submission| submission.user == current_user }.first
      redirect_to @submission
    end
  end

  # Grade all
  def grade_all
    @assignment = Assignment.find(params[:id])
    @course = @assignment.course
    @submissions = @assignment.submissions
    @submissions.each do |submission|
      submission.instructor_grade
    end
    @test_case = @assignment.test_case 
    render "assignments/manage"
  end

  # Show all the grades of the assignment
  def all_grades
    @assignment = Assignment.find(params[:id])
  end

  # Download the grades
  def download_grades
    @assignment = Assignment.find(params[:id])
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet :name => 'Student'
    fmt = Spreadsheet::Format.new :number_format => '0.0'
    sheet.column(2).default_format = fmt

    head = Spreadsheet::Format.new :weight => :bold, :size => 24, :horizontal_align => :center, :vertical_align => :middle
    sheet.merge_cells(0,0,2,2)
    sheet.row(0).default_format = head
    sheet.row(0).push @assignment.name + " Grades"

    top = Spreadsheet::Format.new :weight => :bold, :size => 18, :horizontal_align => :center
    sheet.row(3).default_format = top
    sheet.row(3).push "First Name", "Last Name", "Grade"

    row = 4
    @assignment.submissions.each do |submission|
      sheet.row(row).push submission.user.name, submission.user.name, submission.grade
      row += 1
    end

    sheet.column(0).width = 30
    sheet.column(1).width = 30
    sheet.column(2).width = 15

    blob = StringIO.new
    book.write blob
    send_data blob.string, :filename => @assignment.name + "_grades.xls", :type => "application/xls"
  end

  # Unsubmit all the submitted assignments
  def unsubmit_all_assignments
    @assignment = Assignment.find(params[:id])
    submissions = @assignment.submissions
    submissions.each do |submission|
      submission.submitted = false
      submission.save
      submission.remove_saved_runs
    end
    redirect_to @assignment
  end

  # Creates the form to modify an assignment
  def edit
    @assignment = Assignment.find(params[:id])
    @course = @assignment.course
  end

  # Updates an assignment
  def update
    @assignment = Assignment.find(params[:id])
    @course = @assignment.course

    convert_dates_to_utc
    if @assignment.update_attributes(assignment_params)
      flash[:notice] = "Assignment updated!"
      redirect_to course_path(@assignment.course)
    else
      render :action => :edit
    end
  end

  # Deletes an assignment
  def destroy
    @assignment = Assignment.find(params[:id])
    flash[:notice] = "Successfully deleted Assignment " + @assignment.name
    @assignment.destroy
    redirect_to :back
  end

  private
  def assignment_params
    params.require(:assignment).permit(:name, :total_grade, :description, :start_date, :due_date, :lock)
  end

  def convert_dates_to_utc
    params[:assignment][:start_date] = Time.at(params[:assignment][:start_date].to_i).utc
    params[:assignment][:due_date] = Time.at(params[:assignment][:due_date].to_i).utc
  end

  def copy_files
    @old_test.upload_data.each do |file|
      upload = @test.upload_data.new()
      upload.create_file(file.name, file.contents, file.file_type)
      upload.save
    end
  end
end
