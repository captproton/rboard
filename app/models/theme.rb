class Theme < ActiveRecord::Base
  default_scope :order => "name asc"
	has_many :users
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def to_s
    File.readlines("#{THEMES_DIRECTORY}/#{name}/style.css").to_s
  end
  
end