=begin
This file is part of SSID.

SSID is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

SSID is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with SSID.  If not, see <http://www.gnu.org/licenses/>.
=end

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, :omniauth_providers => [:google_oauth2]
  MIN_PASSWORD_LENGTH = 8

  has_many :memberships , class_name: "UserCourseMembership", :dependent => :delete_all
  has_many :guest_users_detail, class_name: "GuestUsersDetail", :dependent => :delete_all
  has_many :courses, -> { distinct }, :through => :memberships
  has_many :assignments, -> { distinct }, :through => :courses
  has_many :submissions, foreign_key: "student_id"

  validates :name, presence: true
  validates :name, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }
  validate :password_complexity

  before_destroy :ensure_an_admin_remains

  def is_some_staff?
    self.courses.any? { |c| c.membership_for_user(self).role == UserCourseMembership::ROLE_TEACHING_STAFF }
  end

  def is_staff_or_ta?
    UserCourseMembership.where(["user_id = ? AND role IN (?, ?)", self.id, 0, 1])
  end

  def full_name
    the_full_name = self.read_attribute(:full_name) || ""
    the_full_name.strip.empty? ? nil : the_full_name
  end

  def active_for_authentication?
    super && self.is_admin_approved?
  end

  def inactive_message
    if !self.is_admin_approved?
      :not_approved
    else
      super # Use whatever other message
    end
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.full_name = auth.info.name # assuming the user model has a name
    end
  end

  private

  def ensure_an_admin_remains
    if self.is_admin and User.where(is_admin: true).count == 1
      errors.add :base, "Cannot delete last admin"
      false
    else
      true
    end
  end

  def password_complexity
    # Regexp extracted from https://stackoverflow.com/questions/19605150/regex-for-password-must-contain-at-least-eight-characters-at-least-one-number-a
    return if password.blank? || password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/

    errors.add :password, 'Complexity requirement not met. Please use: 1 uppercase, 1 lowercase, 1 digit and 1 special character'
  end
  
end

