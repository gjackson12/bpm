class ReqWorkgroup < ActiveRecord::Base
  include ReqMain
  after_initialize :init
  after_create :set_assignee
  has_many :assignments, as: :assignable   
  validates :name, presence: true
  belongs_to :last_user, class_name: "User"
  has_many :history, as: :historyable

  has_many :inf_workgroup_members, dependent: :destroy
  accepts_nested_attributes_for :inf_workgroup_members, allow_destroy: true,
    reject_if: proc { |attributes| attributes['user_id'].blank? }

  # validate :one_group_leader

  state_machine :initial => :new do
    # before_transition :new => :active, :do => :create_assignment
    before_transition :active => :closed, :do => :close_myassignment
    after_transition any => any, :do => :write_history

    event :initiate do
      transition :new => :active
    end

    event :close do
    	transition :active => :closed
    end   

  end

  private

  def init
    self.state ||= 'new'
    @disabled = Hash.new{|hash, key| hash[key] = Hash.new}
    @disabled["new"]["name"] = false
    @disabled["new"]["money"] = false    
    @disabled["new"]["description"] = false    
    @disabled["active"]["name"] = false
    @disabled["active"]["money"] = false    
    @disabled["active"]["description"] = false     
  end  

  def close_myassignment
    Rails.logger.info('!!!!! close_assignment')  
    close_assignment(self.last_user_id)
  end

  #validations

  # def one_group_leader
  #   Rails.logger.info('!!!!! one_group_leader')
  #   Rails.logger.info(self.inf_workgroup_members.where(main: true).count)
  #   if self.inf_workgroup_members.where(main: true).count > 1
  #     errors.add(:base, :validate_one_leader)
  #   end
  # end 

end
