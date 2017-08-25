class Comment < ActiveRecord::Base
  belongs_to :upload_datum
  validates :contents, presence: true
  validates :line, numericality: { :greater_than => 0, only_integer: true }, presence: true

  validate :comment_is_unique

  def create_comment(file_data)
    self.row = file_data.original_filename
    self.text = file_data.read
    self.type = file_data.content_type
  end

  private
  def comment_is_unique
    errors.add(:base, "Comment is a duplicate") if not upload_datum.comments.where(:contents => contents).where(:line => line).blank?
  end

end
