class RunSave < ActiveRecord::Base
  belongs_to :submission
  belongs_to :input
end
