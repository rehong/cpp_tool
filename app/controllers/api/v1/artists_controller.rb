class Api::V1::ArtistsController < Api::V1::BaseController

  before_action :get_artist, only: [:show, :update, :destroy, :tracks, :albums, :multis]
  # Get /artists
  #before_action  :config_bos_client, only: [:index]

  def index
    page = params.fetch(:page, 1).to_i
    size = params[:size]
    @artists = Artist.includes(:tracks, :country, :audits, :albums).recent
    @artists = @artists.db_query(:name, params[:name]) if params[:name].present?
    @artists = @artists.where(name: params[:check_name]) if params[:check_name].present?
    @artists = @artists.where(status: params[:status]) if params[:status].present?
    @artists = @artists.page(page).per(size)
    render json: {artists: @artists.as_json(Artist.as_list_json_options), meta: page_info(@artists)}
  end

  # Get /artists/:id
  def show
    if @artist
      render json: {artist: @artist.as_json(Artist.as_show_json_options)}
    else
      render json: @artist.errors, status: :unprocessable_entity
    end
  end

  # Put /artists/:id
  def update
    @artist.status = :pending
    if @artist.update(artist_params)
      render json: @artist
    else
      render json: @artist.errors, status: :unprocessable_entity
    end
  end

  # Post /artists
  def create
    @artist = Artist.new(artist_params)
    if @artist.save
      render json: @artist
    else
      render json: @artist.errors, status: :unprocessable_entity
    end
  end

  # Delete /artists/:id
  def destroy
    if @artist.destroy
      render json: @artist
    else
      render json: @artist.errors, status: :unprocessable_entity
    end
  end

  def multis
    @languages = @artist.multi_languages
    render json: {multi_languages: @languages.as_json({only: [:name], methods: :language_name})}
  end

  #批量审核通过
  def accept
    @artists = get_artist_by_ids.limit(20)
    comment = '审核通过'
    @artists.each do |artist|
      artist.without_auditing do
        artist.accept!
      end
      if artist.previous_changes.present?
        changes = {status: artist.previous_changes['status']}
        artist.create_auditables(current_user, 'accept', comment, changes)
      end
    end
    head :ok
  end

  #拒绝通过
  def reject
    comment = params['not_through_reason'] || '审核未通过'
    @artist = get_artist
    @artist.without_auditing do
      @artist.reject!(comment)
    end
    if @artist.previous_changes.present?
      changes = {status: @artist.previous_changes['status']}
      @artist.create_auditables(current_user, 'reject', comment, changes)
    end
    head :ok
  end

  def tracks
    page = params.fetch(:page, 1).to_i
    size = params[:size]
    @tracks = @artist.tracks.includes(:albums, :primary_artists, :audits).recent.page(page).per(size)
    render json: {tracks: @tracks.as_json(Track.as_artlist_tracks_json_options), meta: page_info(@tracks)}
  end

  # POST /artists/export
  def export
    ids = (params[:ids] || '').split(',')

    return render text: '请选择要导出的id列表' if ids.empty?
    return render text: '一次最多导出2000条数据' if ids.length > 2000

    @artists = Artist.where(id: ids)
    render xlsx: 'artists/export.xlsx.axlsx', filename: '艺人列表.xlsx', xlsx_author: 'topdmc.com'
  end

  def albums
    page = params.fetch(:page, 1).to_i
    size = params[:size] || 5
    @albums = @artist.albums.recent.page(page).per(size)
    render json: {albums: @albums, meta: page_info(@albums)}
  end


  private

  def get_artist
    @artist ||= Artist.find(params[:id])
  end

  def get_artist_by_ids
    Artist.where(id: params[:artist_ids])
  end

  def artist_params
    params
      .require(:artist)
      .permit(
        :id,
        :name,
        :country_id,
        :gender_type,
        :description,
        :label_id,
        :label_name,
        :website,
        :not_through_reason,
        :status,
        :audit_comment,
        songs_attributes: [:id, :url, :native_name, :_destroy],
        images_attributes: [:id, :url, :native_name, :_destroy],
        multi_languages_attributes: [:id, :name, :language_id, :_destroy]
      )
  end

  def config_bos_client
    BosClient.configure do |config|
          config.scheme = 'http'
          config.url = 'bcebos.com'
          config.location = 'bj'
          config.expiration_in_seconds = 1800
          config.access_key_id = Rails.application.secrets.bos_ak
          config.secret_access_key = Rails.application.secrets.bos_sk
    end
  end
end
