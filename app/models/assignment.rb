class Assignment < ActiveRecord::Base
  belongs_to :course
  has_many :submissions
  has_one :test_case

  validates :name, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :due_date, presence: true
  validates :total_grade, presence: true
  validate :due_date_after_start_date

  after_save :create_submissions_for_students
  after_save :create_test_case

  def create_submissions_for_students
    course.users.select { |user| user.has_local_role? :student, course }.each do |student|
      submission = submissions.create(user: student) unless submissions.exists?(user: student)
    end
  end

  def create_test_case
    test_case = TestCase.create(:assignment_id => id)
  end

  def copy(assignment_old)
    self.name = assignment_old.name
    self.description = assignment_old.description
    self.due_date = DateTime.now + 10.days
    self.start_date = DateTime.now
    self.total_grade = assignment_old.total_grade
    self.save
  end

  def destroy
    submissions.each do |s|
      s.destroy
    end
    test_case.destroy
    super
  end

  def get_all_comments
    comments = Hash.new
    submissions.each do |s| 
      s.upload_data.each do |u|
        u.comments.each do |c|
          if comments[c.contents] == nil
            comments[c.contents] = 0
          end
          comments[c.contents] += 1
        end
      end 
    end
    return comments
  end

  def remove_saved_runs
    submissions.each do |s|
      s.remove_saved_runs
    end
  end

  private
  def due_date_after_start_date
    errors.add(:due_date, "can't be before start date") if due_date < start_date
  end
end
