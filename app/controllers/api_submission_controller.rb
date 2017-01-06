class ApiSubmissionController < BaseApiController
  
  #Test method to receive data

  before_filter only: :create do
    unless @json.has_key?('submission') && @json['submission'].responds_to?(:[]) && @json['submission']['id']
      render nothing: true, status: :bad_request
    end
  end

  before_filter only: :data do 
    unless @json.has_key?('submission') 
      render nothing: true, status: :bad_request
    end
  end

  def data

  # Validate the key in the JSON to the key saved in the submission
    submission = Submission.find(@json['submission']['id'])
    verify_key = @json['key']
    if submission.key == verify_key
      submission.remove_saved_runs
      puts @json['Compile']['Status']
      
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
          #puts "sample : #{key} => #{value}"
          unless value.has_key?('Result')

            render nothing: true, status: :bad_request
          end
          
          value['Result'].each do |key, value|
            #puts "inputs : #{key} => #{value}"
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

  def poll
    puts " +++++++++++++++++++++++++++++++++++++++++++++++++++++++="
    puts " ++++++++++++++++++calling polls controller+++++++++++++++++++++++++++++++++++++="
    puts " +++++++++++++++++++++++++++++++++++++++++++++++++++++++="
    render nothing: true and return

  end


end
