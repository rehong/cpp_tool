class Cp::Contract < ApplicationRecord
  include ApproveWorkflow
  self.table_name=:cp_contracts
  acts_as_paranoid :column => 'deleted', :column_type => 'boolean', :allow_nulls => false
  audited
  belongs_to :provider
  belongs_to :department
  has_one :trade, as: :target, :dependent => :destroy
  has_many :audits, -> { order(version: :desc) }, as: :auditable, class_name: Audited::Audit.name # override default audits order
  has_many :authorizes,class_name: 'Cp::Authorize', :dependent => :destroy
  has_many :authorize_valids, -> {where('cp_authorizes.end_time >=?',Time.now)},class_name: 'Cp::Authorize'
  has_many :authorize_dues, -> {where('cp_authorizes.end_time <?',Time.now)},class_name: 'Cp::Authorize'
  #has_many :assets, as: :target, :dependent => :destroy
  has_many :contract_resources, as: :target, :dependent => :destroy

	accepts_nested_attributes_for :contract_resources, :allow_destroy => true
  accepts_nested_attributes_for :authorizes ,   :allow_destroy => true

  enum pay_type: [:default,:divide,:undivide]
  enum status: [:pending,:accept,:reject]

  after_create :set_pay_amount_total
  before_save :add_audit_comment
  #validates_presence_of :authorizes

  scope :recent, -> { order('cp_contracts.id DESC') }
  scope :date_between, lambda{ |status|
                             case status
                             when 'valid'   #有效
                               where("start_time < ? AND end_time > ?", Time.now,Time.now)
                             when 'near'   #快到期
                               where("end_time > ? AND end_time < ?", Time.now,Time.now.months_since(3))
                             when 'due'   #过期
                               where("end_time < ?", Time.now)
                             when 'unvalid' #未生效
                               where("start_time > ?", Time.now)
                             end
                           }

  scope :auth_between,  lambda{ |auth|
                             case auth
                             when 'valid'   #有效
                               where('cp_authorizes.end_time >=?',Time.now)
                             when 'due'   #过期
                               where('cp_authorizes.end_time <?',Time.now)
                             end
                           }

   #有效授权数量
   def authorize_valid_cnt
       authorize_valids.size
   end
   #过期授权数量
   def authorize_due_cnt
      authorize_dues.size
   end

   def provider_name
      provider.try(:name)
   end

   def department_name
     department.try(:name)
   end

   def audit_name
     audits.first.try(:username)
   end

   def  contract_status
     if  start_time && end_time
       if  end_time <= Time.now.months_since(3)
        return 'near'
       elsif start_time <=Time.now && end_time >= Time.now
        return 'valid'
       elsif end_time <= Time.now
        return 'due'
       elsif start_time > Time.now
         return 'unvalid'
       end
     end
   end



   class_attribute :as_list_json_options
   self.as_list_json_options={
       only: [:id, :contract_no, :project_no, :provider_id, :start_time,:end_time,:status,:allow_overdue,:pay_type,:not_through_reason,:desc,:created_at, :updated_at],
       methods: [:contract_status,:provider_name,:authorize_valid_cnt,:authorize_due_cnt,:audit_name,:department_name]
   }

   class_attribute :as_show_json_options
    self.as_show_json_options={
      only: [:id, :contract_no,:department_id, :project_no, :provider_id, :start_time,:end_time,:status,:allow_overdue,:pay_type,:pay_amount,:not_through_reason,:desc,:created_at, :updated_at],
      methods: [:contract_status,:provider_name,:authorize_valid_cnt,:authorize_due_cnt,:audit_name,:department_name],
      include: [:contract_resources,authorizes: {include:[:contract_resources,authorized_businesses: {include:[:authorized_areas],methods: [:authorized_range_name]}]}],

    }


   private

   def add_audit_comment
     unless audited_changes.empty?
        self.audit_comment = '合约数据发生变更' if self.id
        self.audit_comment = '新建合约' if self.id.blank?
     end
   end

   def set_pay_amount_total
     if pay_amount.to_i > 0
        trade = self.build_trade(provider_id: provider_id,amount: pay_amount,status: :prepay)
        if trade.save
           provider.update(current_amount: provider.current_amount + trade.amount)
        end
     end
   end

end
