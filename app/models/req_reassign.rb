class ReqReassign < ActiveRecord::Base
  after_initialize :init
  belongs_to :user 
  validates :name, presence: true
  # validates :manager, presence: true
  validates :money, presence: true    
    state_machine :initial => :new do
    before_transition any => :check_approval, :do => :set_role_system
    after_transition any => :check_approval, :do => :check_need_approval
    before_transition any => [:approved, :disapproved], :do => :set_role_manager
    before_transition any => [:accepted_approved, :accepted_disapproved], :do => :set_role_system
    before_transition any => any, :do => :set_new_user

    event :initiate do
      transition :new => :check_approval
    end

    event :check_approval_no do
      transition :check_approval => :dont_need_approval
    end

    event :check_approval_yes do
      transition :check_approval => :wait_approval
    end

    event :approve do
      transition :wait_approval => :approved
    end

    event :disapprove do
    	transition :wait_approval => :disapproved
    end

    event :accept do
    	transition :approved => :accepted_approved, :disapproved => :accepted_disapproved
    end

    event :repeat do
    	transition [:approved, :disapproved] => :wait_approval
    end

  end

  def init
    self.role ||= 'manager'
    self.state ||= 'new' 
  end

  def set_role_ceo
    self.role = 'ceo'
  end

  def set_role_manager
    self.role = 'manager'
  end

  def set_role_system
    self.role = 'system'
  end

  def check_need_approval
  	if self.money > 1000
  		self.set_role_ceo
  		self.check_approval_yes
  	else
  		self.check_approval_no
  	end
  end

  def set_new_user
    if User.where(email: self.manager).exists?
      self.user = User.where(email: self.manager).first
    end
  end

end
