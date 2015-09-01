class UploadDataController < ApplicationController
  before_filter :require_user
  before_filter :require_data_owner, :only => [:destroy]
  before_filter :require_destination_owner, :only => [:create]
  before_filter :require_instructor_owner, :only => [:show, :download_file]
  before_filter :require_not_submitted, :only => [:update]

  # Creates a new upload data
  def create
    if (params[:type] == "submission")
      destination = Submission.find(params[:destination_id])
      destination.remove_saved_runs
    elsif (params[:type] == "test_case")
      destination = TestCase.find(params[:destination_id])
    end

    if params[:file].blank? 
      flash[:notice] = "No File Selected"
      redirect_to :back and return
    end

    upload_data = destination.upload_data.select { |upload| upload.name == params[:file].original_filename }.first
    upload_data = destination.upload_data.create if upload_data.nil?
    upload_data.create_file_from_data(params[:file])
    upload_data.save
    
    respond_to do |format|
      msg = { :status => "ok", :message => "Success!" }
      format.json  { render :json => msg }
    end
  end

  def create_blank
    if (params[:type] == "submission")
      destination = Submission.find(params[:destination_id])
      destination.remove_saved_runs
    elsif (params[:type] == "test_case")
      destination = TestCase.find(params[:destination_id])
    end

    upload_data = destination.upload_data.new(upload_data_params)
    if upload_data.save
      redirect_to :back and return
    else
      redirect_to :back, :notice => "File failed to save" and return
    end
  end

  # Shows an upload data
  def show
    @upload_datum = UploadDatum.find(params[:id])
    source = @upload_datum.source
    course = @upload_datum.source.assignment.course
    file_type = @upload_datum.file_type

    if source.class.name == "TestCase"
      @can_edit = current_user.has_local_role? :grader, course
      send_data @upload_datum.contents, type: 'application/pdf', filename: @upload_datum.name, disposition: 'inline' and return if file_type == 'application/pdf'
      send_data @upload_datum.contents, type: @upload_datum.file_type, filename: @upload_datum.name, disposition: 'inline' and return if file_type.include? "image"
      render "upload_data/edit_no_comments" and return
    end

    submission = @upload_datum.submission
    @can_edit = (submission.user == current_user and not submission.submitted)
    @can_comment = current_user.has_local_role? :grader, course
    @all_comments = get_all_comments(submission.assignment).sort_by { |_key, value| value }.reverse
    @file_comments = @upload_datum.comments

    if file_type == 'application/pdf'
      send_data @upload_datum.contents, type: 'application/pdf', filename: @upload_datum.name, disposition: 'inline' and return
    elsif file_type.include? "image"
      send_data @upload_datum.contents, type: @upload_datum.file_type, filename: @upload_datum.name, disposition: 'inline' and return
    elsif file_type.include? "text" or file_type.include? "application"
      if current_user.has_local_role? :grader, course
        @new_comment = Comment.new
        render "upload_data/edit_grader" and return
      elsif current_user.has_local_role? :student, course or current_user.has_role? :admin
        render "upload_data/edit_student" and return
      end
    else
      flash[:notice] = "Cannot display that file type."
      redirect_to :back and return
    end
  end

  # Updates an upload data
  def update
    upload_datum = UploadDatum.find(params[:id])
    source = upload_datum.source

    if upload_datum.update_attributes(upload_data_params)
      respond_to do |format|
        format.js { render :action => "refresh" }
        format.json { render :json => upload_datum }
      end

      if source.class.name == "Submission"
        source.remove_saved_runs
      else
        source.assignment.remove_saved_runs
      end
    end
  end

  # Removes the file
  def destroy
    @upload_data = UploadDatum.find(params[:id])
    @upload_data.destroy
    source = @upload_data.source
    if source.class.name == "Submission"
      redirect_to upload_datum_url(@upload_data) if @upload_data.submission.submitted
      source.remove_saved_runs
    end
    flash[:notice] = "File successfully deleted"
    redirect_to :back and return
  end

  def download_file
    @upload_data = UploadDatum.find(params[:id])
    send_data @upload_data.contents, :type => @upload_data.file_type , :filename => @upload_data.name
  end

  private
  def upload_data_params
    params.require(:upload_datum).permit(:name, :contents, :file_type, :shared)
  end

  def require_data_owner
    upload_data = UploadDatum.find(params[:id])
    source = upload_data.source

    if source.class.name == "TestCase"
      if not current_user.has_local_role? :grader, source.assignment.course
        flash[:notice] = "Only the course instructor may edit test cases"
        redirect_to dashboard_url
      end
    elsif current_user != source.user
      flash[:notice] = "That action is only available to the file owner"
      redirect_to dashboard_url
    end
  end

  def require_destination_owner
    if (params[:type] == "submission")
      destination = Submission.find(params[:destination_id])
      if current_user != destination.user
        flash[:notice] = "That action is only available to the submission owner"
        redirect_to dashboard_url
      end
    elsif (params[:type] == "test_case")
      destination = TestCase.find(params[:destination_id])
      if current_user.has_local_role? :instructor, destination.assignment
        flash[:notice] = "That action is only available to the course instructor"
        redirect_to dashboard_url
      end
    end
  end

  def require_instructor_owner
    return if current_user.has_role? :admin

    upload_data = UploadDatum.find(params[:id])
    course = upload_data.source.assignment.course
    if upload_data.source.class.name == "TestCase"
     if (not current_user.has_local_role? :grader, course) and !upload_data.shared
        flash[:notice] = "Only graders and instructors may edit test cases"
        redirect_to dashboard_url
      end
    elsif upload_data.source.class.name == "Submission" and (not (current_user.has_role? :grader, course) and current_user != upload_data.submission.user)
      flash[:notice] = "That action is only available to graders or the file owner"
      redirect_to dashboard_url
    end
  end

  def require_not_submitted
    upload_data = UploadDatum.find(params[:id])
    return if upload_data.source.class.name == "TestCase"

    if upload_data.source.submitted
      flash[:notice] = "You may not edit files after submitting your assignment"
      redirect_to dashboard_url
    end
  end

  def get_all_comments(assignment)
    comments = Hash.new
    assignment.submissions.each do |s| 
      s.upload_data.each do |u|
        u.comments.each do |c|
          if comments[c.contents] == nil
            comments[c.contents] = 0
          end
          comments[c.contents] += 1
        end
      end 
    end
    return comments
  end

end
