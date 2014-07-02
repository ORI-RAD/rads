class Annotation < ActiveRecord::Base
  belongs_to :creator, class_name: 'User'
  belongs_to :record
  validates_presence_of :creator_id
  validates_presence_of :record_id
  validates_presence_of :term
  validates_uniqueness_of :term, scope: [:creator_id, :record_id, :context], allow_nil: true

  def to_s
    [creator_id, record_id, context, term].join(' ')
  end
end
