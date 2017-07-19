class TestCasesController < ApplicationController
  skip_before_filter :require_user, :only => [:data_output]
  before_filter :require_grader, :only => [:show, :update, :create_output]
  require 'json'
  require "uri"
  require "net/http"
  # Shows a test case
  def show
    @test_case = TestCase.find(params[:id])
    @run_method = RunMethod.new
    @run_methods = @test_case.run_methods
    @blank_file = UploadDatum.new
  end

  # Updates the test case
  def update
    test_case = TestCase.find(params[:id])

    if test_case.update_attributes(test_case_params)
      flash[:notice] = "Test Case updated!"
    end
    respond_to do |format|
      format.js { render :action => "refresh_variables" }
    end
  end

  def run_method_update
    @test_case = TestCase.find(params[:id])
    @test_case = @test_case.run_methods
    respond_to do |format|
      format.js { render :action => "create_output" }
    end
  end

  def update_data
    test_case = TestCase.find(params[:id])
    trc = 0
    test_case.run_methods.map do |run|
      run.inputs.map do |input|
        trc += 1
      end
    end
  
    respond_to do |format|
      format.json { render :json => {:trc => trc } }
    end
  end
  # Create the output files
  def create_output
    test_case = TestCase.find(params[:id])
    tempDirectory = Rails.configuration.compile_directory + current_user.netid.tr(" ", "_") + '_' + test_case.id.to_s + '/'
    if not Dir.exists?(tempDirectory) 
      Dir.mkdir(tempDirectory)
    end
#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#
    # Adds in the test case files
    #test_case.create_directory(tempDirectory)

    #Compiles and runs the program
    #comp_status = test_case.compile_code(tempDirectory)

    #if comp_status.nil?
     # flash[:notice] = "Outputs Made"
    #else
      #flash[:notice] = "No Outputs Made"
      #flash[:comperr] = comp_status
    #end

    FileUtils.rm_rf(tempDirectory)

    respond_to do |format|
      format.js { render :action => "refresh_output" }
    end

    #*********************************************************************#

    puts "**********************test_case****************************"

    @details = {:username => current_user.netid, :userid =>current_user.id, :course => get_course.name, :assignmentname => get_assignment.name, :assignmentid => test_case.assignment_id, :cputime => test_case.cpu_time, :coresize => test_case.core_size, :test_case_id => test_case.id }
    puts @details

    @RunMethods = test_case.run_methods.map do |run|
      run.inputs.map do |input|
        {:Method => run.name, :Id => input.run_method_id, :command =>run.run_command, :input_id => input.id, :name => input.name, :content => input.data}
      end
    end
    puts @RunMethods
    @sourcefiles = test_case.upload_data.map do |upload_datum|
      if upload_datum.file_type != 'application/pdf'
        if !upload_datum.shared
          { :name => upload_datum.name, :content => upload_datum.contents}
        end
      end
    end
    puts @sourcefiles

    test_case.upload_data.map do |upload_datum|
      if upload_datum.shared
        @makefile = { :name => upload_datum.name,  :content => upload_datum.contents}
      end
    end
    puts @makefile
    json = {:details => @details, :RunMethods => @RunMethods, :sourcefiles => @sourcefiles, :sharedfiles => @makefile}.to_json
    puts json

    # Test Case sending to Flask app
    uri = URI('http://hpcvis6.cse.unr.edu:5000/testcase')
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    req.body = {:details => @details, :RunMethods => @RunMethods, :sourcefiles => @sourcefiles, :sharedfiles => @makefile}.to_json
    res = http.request(req)
    test_case.key = res.body
    test_case.save

  end

  
  
  private
    def test_case_params
      params.require(:test_case).permit(:cpu_time, :core_size)
    end

    def require_grader
      test_case = TestCase.find(params[:id])
      if not current_user.has_local_role? :grader, test_case.assignment.course
        flash[:notice] = "Only the course instructor may edit test cases"
        redirect_to courses_url
      end
    end

    # Gets the course this test case belongs to
    def get_course
	    return TestCase.find(params[:id]).assignment.course
    end
    helper_method :get_course
  
    # Gets the course this test case belongs to
    def get_assignment
      return TestCase.find(params[:id]).assignment
    end
    helper_method :get_assignment
end
