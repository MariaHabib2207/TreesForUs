# app/helpers/life_activities_helper.rb
module LifeActivitiesHelper
  def visibility_icon(visibility)
    {
      "private"            => "🔒 Only Me",
      "friends"            => "👥 Friends",
      "family"             => "🏠 Family",
      "friends_and_family" => "🌐 Friends & Family"
    }[visibility]
  end

  def category_emoji_for(category)
  {
    "travel"    => "✈️",
    "kids"      => "👶",
    "marriage"  => "💍",
    "education" => "🎓",
    "career"    => "💼",
    "milestone" => "🏆",
    "other"     => "⭐"
  }[category] || "⭐"
end
end
