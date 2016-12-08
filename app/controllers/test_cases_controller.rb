class TestCasesController < ApplicationController
  before_filter :require_grader, :only => [:show, :update, :create_output]

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

  # Create the output files
  def create_output
    test_case = TestCase.find(params[:id])
    tempDirectory = Rails.configuration.compile_directory + current_user.netid.tr(" ", "_") + '_' + test_case.id.to_s + '/'
    if not Dir.exists?(tempDirectory) 
      Dir.mkdir(tempDirectory)
    end

    # Adds in the test case files
    test_case.create_directory(tempDirectory)

    # Compiles and runs the program
    comp_status = test_case.compile_code(tempDirectory)

    if comp_status.nil?
      flash[:notice] = "Outputs Made"
    else
      flash[:notice] = "No Outputs Made"
      flash[:comperr] = comp_status
    end

    FileUtils.rm_rf(tempDirectory)

    respond_to do |format|
      format.js { render :action => "refresh_output" }
    end
  end
  
  private
    def test_case_params
      params.require(:test_case).permit(:cpu_time, :core_size)
    end

    def require_grader
      test_case = TestCase.find(params[:id])
      if not current_user.has_local_role? :grader, test_case.assignment.course
        flash[:notice] = "Only the course instructor may edit test cases"
        redirect_to dashboard_url
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
