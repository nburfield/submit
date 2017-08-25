class UploadDatum < ActiveRecord::Base
  belongs_to :test_case
  belongs_to :submission
  has_many :comments

  validates :name, presence: true
  validate :name_is_available
  #validate :name_is_unique
  
  before_save :overwrite_existing_file

  def create_file_from_data(file_data)
  	self.name = file_data.original_filename
  	self.contents = file_data.read
  	self.file_type = file_data.content_type
  end

  def create_file(name, contents, type)
    self.name = name
    self.contents = contents
    self.file_type = type
    self.save
  end

  def source
    return test_case unless test_case.nil?
    return submission unless submission.nil?
  end

  private
  def overwrite_existing_file
    return if contents.nil?
    source.upload_data.each do |file|
      file.destroy if file.name == name and file != self
    end
  end

  def name_is_available
    return if submission.nil?
    submission.assignment.test_case.upload_data.select { |u| u.shared }.each do |upload_datum|
      errors.add(:name, "is the name of a shared file") if upload_datum.name == name
    end
  end

  def name_is_unique
    source.upload_data.each do |upload_datum|
      if upload_datum.id != id and upload_datum.name == name
        puts "This incident hit ======================================================="
        errors.add(:name, "is already taken as a file name")
        return
      end
    end
  end
end
