class Article < ActiveRecord::Base
  validates :title, :presence => true, :uniqueness => true
  validates :body, :presence => true

  has_many :comments
  has_many :taggings
  has_many :tags, :through => :taggings

  default_scope :include => [:comments, :tags]

  def to_s
    return title
  end

  def tag_list
     tags.collect{|t| t.name}.join(", ")
  end

  def self.most_popular
    all.sort_by{|a| a.comments.count }.last
  end

  def tag_list=(input)
    #self.tags = []
    names = input.split(",").collect{|text| text.strip.downcase}
    names.each do |name|
      tag = Tag.find_or_create_by_name(name)
      self.tags << tag unless self.tags.include?(tag)
    end
    self.tags = self.tags.select{|tag| names.include?(tag.name)}
  end

  def self.valid_ids
    Article.select(:id).collect{|a| a.id}
  end

  def self.search_by_tag_name(tag_name)
    if tag_name.blank?
      [Article.scoped, nil]
    else
      tag = Tag.find_by_name(tag_name)
      tag ? [tag.articles, tag] : [[], nil]
    end
  end

  def self.for_dashboard
    order('created_at DESC').limit(5)
  end

  def word_count
    body.split.count
  end

  def self.total_word_count
    all.inject(0) {|total, a| total += a.word_count }
  end
  
  def self.generate_samples(quantity = 1000)
    tags = Tag.all
    quantity.times do
      article = Fabricate(:article)
      article.created_at = article.created_at - (rand(300) + 100).hours
      article.tags = tags.sort_by{ rand }[0..rand(tags.length)]
      article.save
      (rand(10) + 1).times do
      	Fabricate(:comment, :article => article, :created_at => article.created_at + rand(100).hours)
      end
      yield if block_given?
    end
  end
end
