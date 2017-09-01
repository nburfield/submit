class ApiSubmissionController < BaseApiController
  before_filter only: :data do 
    unless @json.has_key?('submission') 
      render nothing: true, status: :bad_request
    end
  end

  before_filter only: :output do 
    unless @json.has_key?('testcase') 
      render nothing: true, status: :bad_request
    end
  end

  def data

  # Validate the key in the JSON to the key saved in the submission
    submission = Submission.find(@json['submission']['id'])
    verify_key = @json['key']
    if submission.key == verify_key
      if not @json['Compile']['Status']
        save = CompileSave.new
        save.output = @json['Compile']['Error']
        save.submission_id = submission.id
        save.save        
      else
        unless @json.has_key?('Run')
          render nothing: true, status: :bad_request
        end

        @json['Run'].each do |key, value|
          unless value.has_key?('Result')
            render nothing: true, status: :bad_request
          end
          
          value['Result'].each do |key, value|
            input = Input.find(key)
            save = RunSave.new(input: input)

            if value["Error"]
              save.difference = value["Error"]
              save.output = value['Error']
            elsif value['Difference'] == nil
              save.difference = "No Difference"
              save.pass = true
            else
              save.difference = value['Difference']
              save.pass = false
            end
            save.submission_id = submission.id
            save.output = value['Output']
            save.save
          end 
        end  
      end
    end
    render nothing: true and return
  end


#Creates testcase output
  def output   
    test_case = TestCase.find(@json['testcase']['id'])
    verify_key = @json['key']
    
    if test_case.key == verify_key
       test_case.assignment.remove_saved_runs

      if not @json['Compile']['Status']
        test_case.run_methods.map do |run|
          run.inputs.map do |input|
            id = input.id
            save = Input.find(id)
            puts save.output
            if save.output == "Outputs not generated" 
              save.output = "Compile Error "
              save.save
              puts save.output
            end
          end
        end
      else 
        unless @json.has_key?('Run')
          render nothing: true, status: :bad_request
        end

        @json['Run'].each do |key, value|
          puts "sample : #{key} => #{value}"

          unless value.has_key?('Result')
            render nothing: true, status: :bad_request
          end

          value['Result'].each do |key, value|
            puts "inputs : #{key} => #{value}"
            input = Input.find(key)
            if value["Error"]
              input.output = value['Error']
            else
              input.output = value['Output']
              input.save
            end
          end
        end
      end
    end
    render nothing: true and return
  end

end
