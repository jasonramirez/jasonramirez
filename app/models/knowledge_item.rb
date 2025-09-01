class KnowledgeItem < ActiveRecord::Base
  validates :title, presence: true
  validates :content, presence: true
  validates :category, presence: true
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :by_category, ->(category) { where(category: category) }
  scope :high_confidence, -> { where('confidence_score >= ?', 0.8) }
  scope :recent, -> { order(last_updated: :desc) }

  def self.search(query)
    return all if query.blank?

    # Split query into words for better matching
    words = query.downcase.split(/\s+/).reject(&:blank?)
    
    # Build a more flexible search query
    conditions = []
    values = {}
    
    words.each_with_index do |word, index|
      conditions << "(LOWER(title) LIKE :word#{index} OR LOWER(content) LIKE :word#{index} OR LOWER(tags) LIKE :word#{index})"
      values["word#{index}".to_sym] = "%#{word}%"
    end
    
    where(conditions.join(' OR '), values)
  end

  def tags_array
    tags.present? ? tags.split(',').map(&:strip) : []
  end

  def tags_array=(tags_array)
    self.tags = tags_array.reject(&:blank?).join(', ')
  end

  def update_timestamp
    update(last_updated: Time.current)
  end
end
