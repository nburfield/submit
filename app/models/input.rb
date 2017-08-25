class Input < ActiveRecord::Base
  belongs_to :run_method

  before_create :default_values
  after_save :remove_saved_runs
  before_destroy :remove_saved_runs

  def remove_saved_runs
  	run_method.test_case.assignment.remove_saved_runs
  end

  private
  def default_values
  	self.name ||= "No Name Set"
  	self.description ||= "No Description Set"
  	self.data ||= "0"
  	self.output ||= "Outputs not generated"
  end
end
