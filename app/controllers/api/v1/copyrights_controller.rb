class Api::V1::CopyrightsController < Api::V1::BaseController

  def index
    page = params.fetch(:page, 1).to_i
    size = params[:size] || 10
    @copyrights = Copyright.order(id: :desc).page(page).per(size)
    render json: {copyrights: @copyrights, meta: page_info(@copyrights)}
  end


  def destroy
    @copyright = Copyright.find(params[:id])
    @copyright.destroy
    head :ok
  end



 
end
