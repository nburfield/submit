class TestCase < ActiveRecord::Base
  belongs_to :assignment
  has_many :upload_data
  has_many :run_methods

  def create_directory(path)
    upload_data.each do |upload_data|
      output = path + upload_data.name
      f = File.open(output, "w" )
      f.write(upload_data.contents)
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
        shell = create_run_script(path, run.run_command, output)
        stdin, stdout, stderr = Open3.popen3(shell)
        stream = stderr.read
        if not stream.empty?
          stream.gsub! path, ""
          if stream.include? "Kill" or stream.include? "Cputime" 
            error_hold = error_hold + "There was an error running input: " + file.name + "\n" + "Error: " + stream + "Process Exceeded Max CPU Time of: " + self.cpu_time.to_s + " seconds.\n\n"
          else
            error_hold = error_hold + "There was an error running input: " + file.name + "\n" + "Error: " + stream + "\n\n"
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
      run_path = directory.gsub(Rails.configuration.compile_directory, "")
      run = "/tmp/" + run_path + command + " < " + file + "\n"
      shell = "#!/bin/bash\n"
      shell = shell + "sudo chroot /var/chroot sudo -u submit bash"
      shell = shell + "ulimit -t " + cpu_time.to_s
      shell = shell + "\n" 
      shell = shell + "ulimit -c " + core_size.to_s
      shell = shell + "\n"
      shell = shell + run
      shell = shell + "exit\n"
      return shell
    end
end
