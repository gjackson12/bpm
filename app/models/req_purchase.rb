class ReqPurchase < ActiveRecord::Base
  after_initialize :init
  after_create :set_assignee
  has_many :assignments, as: :assignable
  validates :money, presence: true    
  validates :name, presence: true
  belongs_to :last_user, class_name: "User"

  state_machine :initial => :new do
    before_transition :new => :wait_approval, :do => :create_assignments
    after_transition :wait_approval => any, :do => :close_assignments

    event :initiate do
      transition :new => :wait_approval
    end

    event :approve do
    	transition :wait_approval => :approved
    end

    event :disapprove do
    	transition :wait_approval => :disapproved
    end    

  end

  # standart public methods

  def is_assigned?(user_id)
    self.assignments.where(closed: false, user_id: user_id).first.nil? ? false : true
  end

  def opened_assignment_users
    assignments = self.assignments.where(closed: false)
    Rails.logger.info('!!!!! opened_assignment_users') 
    Rails.logger.info(assignments.count) 
    if assignments.count > 0
      assignments.map {|x| x.user.name }.join(', ')
    else
      ""
    end
  end  

  def is_disabled?(field)
    res = @disabled[self.state][field]
    res = true if res.nil?
    res
  end  

  private

  def init
    self.last_user_id ||= User.where("email = ?", "admin@test.co").first.id
    self.state ||= 'new'
    # set false to show field for state in edit form    
    @disabled = Hash.new{|hash, key| hash[key] = Hash.new}
    @disabled["new"]["name"] = false
    @disabled["new"]["money"] = false    
    # @disabled["wait_approval"]["money"] = false    
  end  

  def close_assignments
    close_assignment(self.last_user_id)
  end

  def create_assignments
    Rails.logger.info('!!!!! create_assignments') 
    # chief_email = OrgStructure.get_chief(self.new_manager.email)
    # new_user_id = User.where("email = ?", chief_email).first.id
    # Rails.logger.info('!!!!!' + self.user.id.to_s) 
    close_assignment(self.last_user_id)
    chief1_id = User.where("email = ?", "chief1@test.co").first.id
    new_assignment(chief1_id)  	
  end

  # standart operations, TODO move to parent class
  def set_assignee 
    # user_id ||= User.where("email = ?", "admin@test.co").first.id
    self.assignments.create(user_id: self.last_user_id, description: self.name)
  end

  def close_assignment(user_id)
    Rails.logger.info('!!!!! close_assignment') 
    Rails.logger.info(user_id)
    current_assignment = self.assignments.where(closed: false, user_id: user_id).first
    current_assignment.update_attributes(closed: true) if !current_assignment.nil?
  end

  def new_assignment(user_id)
    Rails.logger.info('!!!!! new_assignment') 
    opened_assignments = self.assignments.where(closed: false, user_id: user_id).count
    if opened_assignments == 0
      self.assignments.create(user_id: user_id, description: self.name)  
    end         
  end

end
