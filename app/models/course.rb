class Course < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :assignments

  validates :name, presence: true
  validates :description, presence: true
  validates :term, presence: true
  validates :year, presence: true
  validate :course_is_unique

  TERMS = %w[spring fall summer winter]

  def generate_join_token
    update(join_token: SecureRandom.base64(8))
  end

  private
  def course_is_unique
    original = Course.where(name: name, term: term, year: year).first
    errors.add(:name, "appears to be a duplicate of " + original.name) unless original.nil? or original == self
  end
end
