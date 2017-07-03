class Api::V1::Cp::SettlementsController < Api::V1::BaseController

  def index
    page = params.fetch(:page, 1).to_i
    size = params[:size]

    @settlements = ::Cp::Settlement.includes(:provider,:dsp,:currency).recent
    @settlements = @settlements.where(dsp_id: params[:dsp_id]) if params[:dsp_id].present?
    @settlements = @settlements.where(id: params[:id]) if params[:id].present?
    @settlements = @settlements.where(provider_id: params[:provider_id]) if params[:provider_id].present?
    @settlements = @settlements.where(settlement_amount: params[:settlement_amount]) if params[:settlement_amount].present?
    @settlements = @settlements.where("settlement_cycle_start >= ?" ,params[:settlement_cycle_start]) if params[:settlement_cycle_start].present?
    @settlements = @settlements.where("settlement_cycle_end <= ?" , params[:settlement_cycle_end]) if params[:settlement_cycle_end].present?
    @settlements = @settlements.where(settlement_date: params[:settlement_date]) if params[:settlement_date].present?
    @settlements = @settlements.page(page).per(size)

    render json:{settlements: @settlements , meta: page_info(@settlements) }
  end

 #确定结算
  def confirm
    @settlement = ::Cp::Settlement.find(params[:id])
    if @settlement.confirm!
       head :ok
    end
  end

 def payment
   @settlement = ::Cp::Settlement.find(params[:id])
   if @settlement.paymented!
      head :ok
   end
 end


end
