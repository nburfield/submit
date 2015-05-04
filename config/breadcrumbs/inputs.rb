crumb :input do |input|
  link input.name, input
  parent :run_method, input.run_method
end

crumb :input_new do |run_method|
  link "Input"
  parent :run_method, run_method
end
