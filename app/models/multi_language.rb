class MultiLanguage < ApplicationRecord
  belongs_to :multilanguage, polymorphic: true
  belongs_to :language

  class_attribute :as_relationship_json_options
	self.as_relationship_json_options={
			only: [:name],
      include: [:language]
	}
end