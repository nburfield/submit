class Submission < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  has_many :upload_data, dependent: :destroy
  has_many :run_saves, dependent: :destroy
  has_many :compile_saves, dependent: :destroy

  after_create :set_note_empty

  # This should be moved to the model
  def set_note_empty
    self.note = ""
    self.save
  end

  # Sets up the directory
  def create_directory
    # Creates a temporary directory for the student files
    tempDirectory = Rails.configuration.compile_directory + user.first_name.tr(" ", "_") + '_' + id.to_s + '/'
    if not Dir.exists?(tempDirectory) 
      Dir.mkdir(tempDirectory)
    end

    # Adds in all the student files 
    upload_data.each do |upload_datum|
      f = File.open(tempDirectory + upload_datum.name, "w")
      f.write(upload_datum.contents.force_encoding("UTF-8"))
      f.close
    end

    # Adds in all the shared test_case files
    assignment.test_case.upload_data.select { |u| u.shared }.each do |upload_datum|
      f = File.open(tempDirectory + upload_datum.name, "w")
      f.write(upload_datum.contents.force_encoding("UTF-8"))
      f.close
    end

    return tempDirectory
  end

  # Compiles and runs the program
  def compile(directory)
    flash = {}
    make = "make -C " + directory
    if system(make)
      flash[:compile] = true
      return flash
    else
      stream = capture(:stderr) { system(make) }
      flash[:compile] = false
      flash[:comperr] = stream
      return flash
    end
  end

  # Runs the code on a test case input
  def run_test_cases(hidden)
    stream = {}
    directory = create_directory

    remove_saved_runs

    assignment.test_case.run_methods.each do |run|
      run.inputs.each do |input|
        # Make output file
        input_file = directory + input.name.tr(" ", "_")
        f = File.open(input_file, "w")
        f.write(input.data)
        f.close

        # Get the shell script and write to file 'script'
        shell = create_run_script(directory, run.run_command, input_file)
        f = File.open(directory + "script", "w")
        f.chmod(0777)
        f.write(shell)
        f.close

        # Build the command that will run the script
        if Rails.configuration.OnServer  
          run_data = 'sudo chroot /var/chroot /bin/bash -c "sh /tmp/'
          run_data = run_data + directory.gsub(Rails.configuration.compile_directory, "") + 'script"'
        else
          run_data = Rails.configuration.compile_directory
          run_data = run_data + directory.gsub(Rails.configuration.compile_directory, "") + 'script'
        end

        # Call the script, and capture output
        stdin, stdout, stderr = Open3.popen3(run_data)

        # Run this check to prevent loading a large file
        stream[:stderr] = stderr.read

        if File.stat(input_file + "_output").size > 65534 # 5MiB
          stream[:stdout] = ""
          stream[:stderr] += "\nOutput File Size was greater than 5MiB. Cannot Display"
        else
          f = File.open(input_file + "_output", "r")
          stream[:stdout] = f.read
          f.close
        end

        save = run_saves.new(input: input)

        # Check if the process errored
        f = File.open(input_file, "w")
        if not stream[:stderr].empty?
          stream[:stderr].gsub! directory, ""
          stream[:stderr] += "\nProcess Exceeded Max CPU Time of: " + assignment.test_case.cpu_time.to_s + " seconds." if stream[:stderr].include? "Kill" or stream[:stderr].include? "Cputime"
          if not stream[:stdout].empty?
            stream[:stderr] = stream[:stdout] + "\n" + stream[:stderr]
          end
          f.write(stream[:stderr])
          f.close
          save.difference = "ERROR"
          save.output = stream[:stderr]
        else 
          f.write(stream[:stdout])
          f.close
          save.output = stream[:stdout]
          save.difference = Diffy::Diff.new(stream[:stdout], input.output, :include_plus_and_minus_in_html => true, :allow_empty_diff => true).to_s()
        end

        save.pass = save.difference.blank?
        save.difference = "No Difference" if save.difference.blank?
        save.save
      end
    end

    FileUtils.rm_rf(directory)
  end

  # Grade the submission 
  def instructor_grade
    directory = create_directory
    gradeData = {}

    # Compiles and runs the program
    gradeData = compile(directory)
    gradeData[:correct] = run_test_cases(false) if gradeData[:compile]

    FileUtils.rm_rf(directory)
    return gradeData
  end

  def remove_saved_runs
    run_saves.each do |rs|
      rs.destroy
    end
    compile_saves.each do |rs|
      rs.destroy
    end
  end

  def visible_run_saves(current_user)
    return run_saves(0).select { |run_save| run_save.input.student_visible } if not (current_user.has_local_role? :grader, assignment.course)
    return run_saves(0)
  end

  private
    # Creates a script to run on
    def create_run_script(directory, command, file)
      # Fix the directory path
      if Rails.configuration.OnServer
        file = "/tmp/" +  file.gsub(Rails.configuration.compile_directory, "")
        directory = "/tmp/" + directory.gsub(Rails.configuration.compile_directory, "")
      end

      # Build the run script
      run = directory + command + " < " + file + " > " + file + "_output" + "\n"

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
