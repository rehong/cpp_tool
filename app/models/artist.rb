class Artist < ApplicationRecord
  include ApproveWorkflow
  audited
  acts_as_paranoid :column => 'deleted', :column_type => 'boolean', :allow_nulls => false
  enum gender_type: [:male, :female, :team]
	enum status: [:pending,:accepted,:rejected]
  validates :name, presence: true
  belongs_to :country
  has_many :audits, -> { order(version: :desc) }, as: :auditable, class_name: Audited::Audit.name
  has_many :multi_languages, as: :multilanguage
  # songs resource association
  has_many :song_resources, -> {where resource_type: 'song'},
           class_name: 'ArtistResource', dependent: :destroy
  has_many :songs, :through => :song_resources, class_name: 'Resource', :source => :resource

  # images resource association
  has_many :image_resources, -> {where resource_type: 'image'},
           class_name: 'ArtistResource', dependent: :destroy
  has_many :images, :through => :image_resources, class_name: 'Resource', :source => :resource


  has_many :artist_tracks, -> { where artist_type: 'Primary' },
            class_name: 'ArtistTrack', :foreign_key => :artist_id
  has_many :tracks, :through => :artist_tracks, class_name: 'Track', :source => :track

  # artist album association
  has_many :artist_albums, -> { where album_type: 'AlbumOfPrimaryArtist' },
            class_name: 'ArtistAlbum', :foreign_key => :artist_id
  has_many :albums, :through => :artist_albums, class_name: 'Album', :source => :album

  # videos association
  has_many :vidoes_types, -> { where artist_type: ['primary','featuring'] },
            class_name: 'ArtistVideo', :foreign_key => :artist_id,
            dependent: :destroy
  has_many :videos, :through => :vidoes_types, class_name: 'Video', :source => :video

  before_save :add_audit_comment

  accepts_nested_attributes_for :songs, :allow_destroy => true
  accepts_nested_attributes_for :images, :allow_destroy => true
  accepts_nested_attributes_for :multi_languages, :allow_destroy => true

  scope :recent, -> {order('id DESC')}


  def country_name
      country.try(:cname)
  end

  def auditer
      audits.first.try(:username)
  end

	class_attribute :as_list_json_options
	self.as_list_json_options={
			only: [:id, :name,:label_id,:label_name,:gender_type,:description,:status,:country_id,:not_through_reason,:website,:created_at,:updated_at,:tracks_count,:albums_count],
      methods: [:country_name,:auditer]
	}

  class_attribute :as_show_json_options
  self.as_show_json_options={
      only: [:id, :name,:label_id,:label_name,:gender_type,:description,:status,:country_id,:not_through_reason,:website,:created_at,:updated_at,:tracks_count,:albums_count],
      include: [:albums,:audits,:tracks,:images,:songs,
        multi_languages: {
          only: [:id,:language_id,:name],
          methods: [:language_name]
        },
        audits: {
          only: [:id,:user_id,:username,:action,:version,
            :remote_address,:comment,:created_at]}
      ],
      methods: [:country_name,:auditer]
  }


  private

  def add_audit_comment
    unless audited_changes.empty?
       self.audit_comment = '艺人数据发生变更' if self.id
       self.audit_comment = '新建艺人' if self.id.blank?
    end
  end


end
