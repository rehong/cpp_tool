class Api::V1::Albums::ShowSerializer < Api::V1::AlbumSerializer
  attributes  :release_date,
    :tracks_count,
    :language,
    :has_explict,
    :p_line_copyright,
    :remark,
    :audits,
    :original_label_number,
    :cd_volume,
    :genre_name,
    :sub_genre_name,
    :updated_at

  def genre_name
    object.genre.try(:name)
  end
  def sub_genre_name
    object.sub_genre.try(:name)
  end
  has_many :primary_artists, serializer: Api::V1::Albums::ArtistSerializer
  has_many :featuring_artists, serializer: Api::V1::Albums::ArtistSerializer
end
