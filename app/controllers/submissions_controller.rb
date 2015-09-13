class SubmissionsController < ApplicationController
  before_filter :require_user
  before_filter :require_owner, :only => [:show, :run, :submit]
  before_filter :require_instructor_owner, :only => [:index, :unsubmit]

  # Shows a submission
  def show
    @submission = Submission.find(params[:id])
    @assignment = @submission.assignment
    @blank_file = UploadDatum.new

    if current_user == @submission.user
      render and return
    end

    if current_user.has_local_role? :grader, get_course
      render :action => :edit and return
    else
      render and return
    end
  end

  # Updates an existing submission
  def update
    submission = Submission.find(params[:id])

    saves = submission.run_saves.each
    if not saves.count > 0
      directory = submission.create_directory
      comp_message = submission.compile(directory)
      FileUtils.rm_rf(directory)
      if comp_message[:compile]
        flash[:notice] = "Run the students program before grading."
        redirect_to :back and return
      else
        submission.assignment.test_case.run_methods.each do |run|
          run.inputs.each do |input|
            save = submission.run_saves.new(input: input)
            save.difference = "ERROR"
            save.output = "Does Not Compile"
            save.pass = false;
            save.save
          end
        end
      end
    end

    if submission.update_attributes(submission_params)
      make_pdf
      flash[:notice] = "Submission updated!"
      redirect_to assignment_url(get_assignment)
    end
  end

  # Compiles but does not run a user's submission
  def compile
    submission = Submission.find(params[:id])
    directory = submission.create_directory

    # Check if program compiled
    comp_message = submission.compile(directory)
    if comp_message[:compile]
      respond_to do |format|
        format.js { render :action => "compile" }
      end
    else
      respond_to do |format|
        format.js { render :action => "compile_error", :locals => { :message => comp_message[:comperr] } }
      end
    end

    # Cleans up the files
    FileUtils.rm_rf(directory)
  end

  # Compiles, runs the code, and creates the output files
  def run
    @submission = Submission.find(params[:id])
    assignment = @submission.assignment
    directory = @submission.create_directory

    # Compiles and runs the program
    comp_message = @submission.compile(directory)
    if comp_message[:compile]
      @submission.run_test_cases(true)
      respond_to do |format|
        format.js { render :action => "run" }
      end
    else
      #flash.now[:comperr] = comp_message[:comperr]
      respond_to do |format|
        format.js { render :action => "compile_error", :locals => { :message => comp_message[:comperr] } }
      end
    end
  end

  # Submit the assignment
  def submit
    @submission = Submission.find(params[:id])
    @assignment = @submission.assignment
    @submission.submitted = true
    @submission.submit_time = Time.now().utc
    @submission.save
    @submission.remove_saved_runs
    flash[:notice] = "Assignment Has Been Submitted"
    redirect_to submission_url(@submission)
  end

  # Un-Submit the assignment
  def unsubmit
    @submission = Submission.find(params[:id])
    @assignment = @submission.assignment
    @submission.submitted = false
    @submission.save
    @submission.remove_saved_runs
    flash[:notice] = "Assignment Has Been Unsubmitted"
    redirect_to submission_url(@submission)
  end

  private
    def submission_params
      params.require(:submission).permit(:grade, :note)
    end

    # Gets the course this submission belongs to
    def get_course
      return Submission.find(params[:id]).assignment.course
    end
    helper_method :get_course

    # Gets the course this submission belongs to
    def get_assignment
      return Submission.find(params[:id]).assignment
    end
    helper_method :get_assignment

    # Checks that the user is the owner of the submission, the course instructor, or an admin
    def require_owner
      submission = Submission.find(params[:id])
      return if current_user.has_role? :admin or current_user.has_local_role? :grader, get_course

      if submission.user != current_user
        flash[:notice] = "You may only view your own submissions"
        redirect_to dashboard_url
      end
    end

    def require_instructor_owner
      return if current_user.has_role? :admin

      submission = Submission.find(params[:id])
      course = submission.assignment.course
      if not current_user.has_role? :instructor, course
        flash[:notice] = "That action is only available to the instructor of the course"
        redirect_to dashboard_url
      end
    end

    # This is for PDF creation
    def make_pdf
      submission = Submission.find(params[:id])

      # File html data
      html_top = '<html>
                    <head>
                      <style type="text/css">
                        body {
                          width: 1056px;
                        }

                        h1 {
                          width: 900px;
                          text-align: center;
                          font-size: 50px;
                          margin-left: auto;
                          margin-right: auto;
                        }

                        hr {
                          width: 1000px;
                          margin-left: auto;
                          margin-right: auto;
                        }

                        h2 {
                          width: 900px;
                          text-align: center;
                          font-size: 30px;
                          margin-left: auto;
                          margin-right: auto;
                        }

                        .top {
                          border: 2px solid black;
                          width: 900px;
                          padding-top: 0;
                          text-align: center;
                          font-size: 20px;
                          margin-left: auto;
                          margin-right: auto;
                          margin-bottom: 10px;
                          padding-bottom: 15px;
                        }

                        .top h2 {
                          margin-top: 0;
                          background-color: rgba(179, 186, 192, 0.79);
                          border-bottom: 1px solid black;
                        }

                        .top p {
                          text-align: left;
                          padding-left: 20px;
                          padding-right: 20px;
                          padding-bottom: 0;
                        }

                        table {
                          width: 900px;
                          margin-left: auto;
                          margin-right: auto; 
                          border: 2px solid black;
                        }

                        #name {
                          margin: 0;
                          text-align: center;
                          width: 130px;
                        }

                        #description {
                          border: 1px solid black;
                          padding: 10px;
                        }

                        #grade {
                          text-align: right;
                          width: 120px;
                          text-transform: uppercase;
                        }

                        th {
                          background-color: rgba(179, 186, 192, 0.79);
                          text-transform: uppercase;
                          border: 1px solid black;
                          margin: 0;
                        }
                      </style>
                    </head>
                    <body> '
      html_name = '<h1>' + submission.user.name + '</h1>'
      html_title = '<h2>Grade Report for ' + submission.assignment.name + '</h2>'
      html_center1 = '<br>
                    <hr>
                    <br>
                    <div class="top">
                      <h2>GRADE</h2>'
      html_grade = submission.grade.to_s + ' out of ' + submission.assignment.total_grade.to_s
      html_center2 = '</div>
                      <div class="top">
                        <h2>NOTES</h2>
                        <p>'
      
      html_note = submission.note.gsub("\n", '<br>')

      html_center3 = '</p>
                    </div>
                    <table>
                      <tr>
                        <th>Input Name</th>
                        <th>Input Description</th>
                        <th>Pass/Fail</th>
                      </tr>'
      html_end = '</table>
                  </body>
                  </html>'

      html_output = ''

      submission.assignment.test_case.run_methods.each do |run|
        run.inputs.each do |input|
          html_output = html_output + '<tr><td id="name">' + input.name + '</td>'
          html_output = html_output + '<td id="description">' + input.description + '</td>'
          save = submission.run_saves.select { |s| s.input_id == input.id }.first
          if not save.pass
            html_output = html_output + '<td id="grade"><font color="red">Fail</font></td></tr>'
          else
            html_output = html_output + '<td id="grade"><font color="green">Pass</font></td></tr>'
          end
        end
      end

      # Load the html to convert to PDF
      #html = File.read(fileDirectory)
      html = html_top + html_name + html_title + html_center1 + html_grade + html_center2 + html_note + html_center3 + html_output + html_end
      kit = PDFKit.new(html, :page_size => 'Letter')
      data = kit.to_pdf

      # Add File to the student, and delete
      upload = submission.upload_data.new()
      upload.create_file('Grade File', data, 'application/pdf')
    end
end
