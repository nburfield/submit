class RunMethod < ActiveRecord::Base
  has_many :inputs
  belongs_to :test_case

  after_save :remove_saved_runs
  before_destroy :remove_saved_runs

  def remove_saved_runs
  	test_case.assignment.remove_saved_runs
  end
end
