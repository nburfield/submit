class TestCase < ActiveRecord::Base
  belongs_to :assignment
  has_many :upload_data
  has_many :run_methods

  def create_directory(path)
    upload_data.each do |upload_data|
      output = path + upload_data.name
      f = File.open(output, "w" )
      f.write(upload_data.contents.force_encoding("UTF-8"))
      f.close
    end
  end

  def compile_code(path)
    error_hold = ""
    make = "make -C " + path
    if not system(make)
      return capture(:stderr) { system(make) }
    end
    
    run_methods.each do |run|
      if run.inputs.nil? or run.inputs.empty?
        file = run.inputs.new
        file.add("No_Inputs", "This is auto-generated for a program with no given inputs.", nil, "", true)
      end
      run.inputs.each do |file|
        output = path + file.name.tr(" ", "_")
        f = File.open(output, "w" )
        f.write(file.data)
        f.close

        # Get the shell script and write to file 'script'
        shell = create_run_script(path, run.run_command, output)
        f = File.open(path + "script", "w")
        f.chmod(0777)
        f.write(shell)
        f.close

        # Build the command that will run the script
        if Rails.configuration.OnServer
          run_data = 'sudo chroot /var/chroot /bin/bash -c "sh /tmp/' 
          run_data = run_data + path.gsub(Rails.configuration.compile_directory, "") + 'script"'
        else
          run_data = Rails.configuration.compile_directory
          run_data = run_data + path.gsub(Rails.configuration.compile_directory, "") + 'script'
        end

        # Call the script, and capture putput
        stdin, stdout, stderr = Open3.popen3(run_data)
        stream = stderr.read
        if not stream.empty?
          stream.gsub! path, ""
          if stream.include? "Kill" or stream.include? "Cputime" 
            error_hold = error_hold + "There was an error running input: " + file.name + "\n" + "Error: " + stream + "Process Exceeded Max CPU Time of: " + self.cpu_time.to_s + " seconds.\n\n"
          else
            error_hold = error_hold + "There was an error running input: " + file.name + "\n" + "Error: " + stream + "\n\n"
          end
          if not stream[:stdout].empty?
            stream[:stderr] = stream[:stdout] + "\n" + stream[:stderr]
          end
        end
        stream = stdout.read
        file.output = stream
        file.save
      end
    end
    return error_hold if not error_hold.empty?
  end

  private
    def create_run_script(directory, command, file)
      # Fix the directory path
      if Rails.configuration.OnServer
        file = "/tmp/" +  file.gsub(Rails.configuration.compile_directory, "")
        directory = "/tmp/" + directory.gsub(Rails.configuration.compile_directory, "")
      end

      # Build the run script
      run = directory + command + " < " + file + "\n"

      # Build the shell script
      shell = "#!/bin/bash\n"
      shell = shell + "ulimit -t " + assignment.test_case.cpu_time.to_s
      shell = shell + "\n" 
      shell = shell + "ulimit -c " + assignment.test_case.core_size.to_s
      shell = shell + "\n"
      shell = shell + run
      shell = shell + "exit\n"
      return shell
    end
end
