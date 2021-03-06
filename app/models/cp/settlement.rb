include Workflow
class Cp::Settlement < ApplicationRecord
	self.table_name=:cp_settlements
	belongs_to :provider
	belongs_to :dsp
	belongs_to :user
	belongs_to :currency
	has_many :transations,as: :target, :dependent => :destroy
	enum status: [:pending, :confirmed, :paymented]
  scope :recent, -> { order('id DESC') }

	workflow_column :status
	workflow do
		state :pending do
			event :confirm, :transitions_to => :confirmed
		end

		state :confirmed do
			event :payment, :transitions_to => :paymented
		end

		state :paymented
	end

  def provider_name
    provider.try(:name)
	end

	def dsp_name
		dsp.try(:name)
	end

	def user_name
		user.try(:name)
	end

  def self.as_list_json_options
     as_list_json = {
    			only: [:id, :settlement_amount,:settlement_cycle_start,:settlement_cycle_end,:settlement_date,:status,:file_url,:created_at,:updated_at],
          methods: [:provider_name,:user_name]
        }
  end

  def self.as_show_json_options
     as_list_json = {
			   only: [:id, :settlement_amount,:settlement_cycle_start,:settlement_cycle_end,:settlement_date,:status,:file_url,:created_at,:updated_at],
			   methods: [:provider_name,:dsp_name,:user_name]
        }
  end

	def payment_transations
		transation = self.transations.new(provider_id: self.provider_id, sort: -1,amount: self.settlement_amount,subject: '结算单金额')
		ActiveRecord::Base.transaction do
			transation.save!
			self.update!(status: :confirmed,settlement_date: Time.now.to_date)
		end
	end

end
