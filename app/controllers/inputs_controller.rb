class InputsController < ApplicationController
  
  # new
  def new
    @input = Input.new
    @run_method = RunMethod.find(params[:run_method_id])
  end

  # create
  def create
    run_method = RunMethod.find(params[:run_method_id])
    input = run_method.inputs.new(input_params)

    if input.save
      redirect_to :back
    else
      redirect_to :back
    end
  end

  # show
  def show
    @input = Input.find(params[:id])
  end

  # edit
  def edit
    @input = Input.find(params[:id])
  end

  # update
  def update
    @input = Input.find(params[:id])

    if @input.update_attributes(input_params)
      redirect_to test_case_url(@input.run_method.test_case_id)
    else
      render :action => :edit
    end
  end

  # delete 
  def destroy
    input = Input.find(params[:id])
    input.destroy
    redirect_to :back
  end

  private
    def input_params
      params.require(:input).permit(:name, :description, :data, :student_visible)
    end
end
