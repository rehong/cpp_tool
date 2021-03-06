class Track < ApplicationRecord
  include ApproveWorkflow
  audited
  has_and_belongs_to_many :albums
  accepts_nested_attributes_for :albums, :allow_destroy => true
  #has_and_belongs_to_many :artists

  # primary artist track association
  has_many :primary_artist_types, -> {where artist_type: 'Primary'},
           class_name: 'ArtistTrack', :foreign_key => :track_id,
           dependent: :destroy
  has_many :primary_artists, :through => :primary_artist_types, class_name: 'Artist', :source => :artist

  # featuring artist track association
  has_many :featuring_artist_types, -> {where artist_type: 'Featuring'},
           class_name: 'ArtistTrack', :foreign_key => :track_id,
           dependent: :destroy
  has_many :featuring_artists, :through => :featuring_artist_types, class_name: 'Artist', :source => :artist

  has_and_belongs_to_many :videos
  belongs_to :language
  belongs_to :provider
  belongs_to :genre
  belongs_to :sub_genre, class_name: 'Genre'
  belongs_to :copyright
  belongs_to :contract, class_name: 'Cp::Contract', foreign_key: :contract_id
  belongs_to :authorize, class_name: 'Cp::Authorize', foreign_key: :authorize_id
  has_many :audits, -> {order(version: :desc)}, as: :auditable, class_name: Audited::Audit.name

  has_many :track_resources
  accepts_nested_attributes_for :track_resources, :allow_destroy => true
  has_many :track_composers
  accepts_nested_attributes_for :track_composers, :allow_destroy => true
  has_many :multi_languages, as: :multilanguage
  accepts_nested_attributes_for :multi_languages, :allow_destroy => true
  acts_as_paranoid :column => 'deleted', :column_type => 'boolean', :allow_nulls => false
  enum status: [:pending, :accepted, :rejected]

  validates :title, :isrc, :language_id, :pline, :cline, presence: true

  before_save :add_audit_comment
  after_save :add_authorizes_track_count
  after_save :execute_sql_dat
  before_destroy :dec_tracks_count
  after_create :inc_tracks_count


  scope :recent, -> {order('id DESC')}
  scope :position_order, -> {order('position ASC')}

  def provider_name
    provider.try(:name)
  end

  def contract_name
    contract.try(:contract_no)
  end

  def genre_name
    genre.try(:name)
  end

  def sub_genre_name
    sub_genre.try(:name)
  end

  def copyright_name
    copyright.try(:name)
  end

  def authorize_name
    "授权书#{authorize.try(:id)}"
  end

  # resources define
  has_many :audio_resources, -> {where(file_type: 1)}, class_name: 'TrackResource'
  has_many :composers_resources, -> {where(file_type: 2)}, class_name: 'TrackResource'
  has_many :material_resources, -> {where(file_type: 3)}, class_name: 'TrackResource'
  has_many :image_resources, -> {where(file_type: 0)}, class_name: 'TrackResource'

  accepts_nested_attributes_for :audio_resources, :allow_destroy => true
  accepts_nested_attributes_for :composers_resources, :allow_destroy => true
  accepts_nested_attributes_for :material_resources, :allow_destroy => true
  accepts_nested_attributes_for :image_resources, :allow_destroy => true

  def audio_resources=(attr)
    self.audio_resources_attributes=attr
  end

  def composers_resources=(attr)
    self.composers_resources_attributes=attr
  end

  def material_resources=(attr)
    self.material_resources_attributes=attr
  end

  def image_resources=(attr)
    self.image_resources_attributes=attr
  end

  def track_composers=(attr)
    self.track_composers_attributes =attr
  end

  def auditer
    audits.first.try(:username)
  end


  class_attribute :as_list_json_options
  self.as_list_json_options={
    only: [:id, :title, :isrc, :status, :language_id, :genre_id, :ost, :lyric, :label, :is_agent, :provider_id, :contract_id, :authorize_id, :remark, :updated_at, :created_at],
    include: [:albums, :primary_artists],
    methods: [:provider_name, :contract_name, :auditer]
  }

  class_attribute :as_relationship_list_json_options

  self.as_relationship_list_json_options={
    only: [:id, :title, :label, :copyright_id, :label_code, :is_agent, :updated_at, :copyright_attribution, :position],
    include: [:primary_artists,
              multi_languages: {
                only: [:id, :language_id, :name],
                methods: [:language_name]
              }
    ],
    methods: [:provider_name, :auditer]
  }

  class_attribute :as_show_json_options
  self.as_show_json_options={
    only: [:id, :title, :isrc, :status, :language_id, :genre_id, :sub_genre_id, :ost, :lyric, :pline, :cline, :label_code, :release_version,
           :copyright_id, :label, :is_agent, :provider_id, :contract_id, :authorize_id, :remark, :created_at],
    include: [
      {:albums => {:only => %w(id name)}},
      {:audits => {:only => %w(id username action comment)}},
      {:primary_artists => {:only => %w(id name country_name)}},
      {:featuring_artists => {:only => %w(id name country_name)}},
      {
        :multi_languages => {
          :only => %w(id language_id name),
          :methods => [:language_name]
        }
      },
      {:audio_resources => {:only => %w(id file_name url)}},
      {:composers_resources => {:only => %w(id file_name url)}},
      {:material_resources => {:only => %w(id file_name url)}},
      {:image_resources => {:only => %w(id file_name url)}},
      {:track_composers => {:only => %w(id name op_type point)}}
    ],
    methods: [:provider_name, :contract_name, :genre_name, :sub_genre_name, :copyright_name, :auditer, :authorize_name]
  }

  #艺人的歌曲列表
  class_attribute :as_artlist_tracks_json_options
  self.as_artlist_tracks_json_options={
    only: [:id, :title, :isrc, :status, :language_id, :genre_id, :ost, :lyric, :label, :is_agent, :provider_id, :contract_id, :authorize_id, :remark, :created_at],
    include: [:albums, :primary_artists,
              multi_languages: {
                only: [:id, :language_id, :name],
                include: [language: {only: [:name]}]
              },
    ]
  }

  private

  def add_audit_comment
    unless audited_changes.empty?
      self.audit_comment = '歌曲数据发生变更' if self.id
      self.audit_comment = '新建歌曲' if self.id.blank?
    end
  end

  def inc_tracks_count
    self.primary_artists.each do |artist|
      Artist.increment_counter('tracks_count', artist.id)
    end
    self.albums.each do |album|
      Album.increment_counter('tracks_count', album.id)
    end
  end

  def dec_tracks_count
    self.primary_artists.each do |artist|
      Artist.decrement_counter('tracks_count', artist.id)
    end
    self.albums.each do |album|
      Album.decrement_counter('tracks_count', album.id)
    end
  end

  def add_authorizes_track_count
    if self.authorize
      authorize_tracks_count = Track.where(authorize_id: self.authorize).count
      contract_tracks_count = Track.where(contract_id: self.contract).count
      authorize.update(tracks_count: authorize_tracks_count)
      contract.update(tracks_count: contract_tracks_count)
    end
  end

  def execute_sql_dat
    sql_artist = "update artists set tracks_count =(select count(*) from artist_tracks join tracks on artist_tracks.track_id = tracks.id and tracks.deleted=0  where artist_tracks.artist_id=artists.id),
    albums_count =(select count(*) from artist_albums join albums on artist_albums.`album_id`=albums.id and albums.deleted=0  where artist_albums.artist_id=artists.id) "
    ActiveRecord::Base.connection.execute(sql_artist)

    sql_blubms = "update albums set tracks_count =(select count(*) from albums_tracks join tracks on albums_tracks.`track_id`=tracks.id and tracks.deleted=0  where albums_tracks.album_id=albums.id)"
    ActiveRecord::Base.connection.execute(sql_blubms)
  end

end
