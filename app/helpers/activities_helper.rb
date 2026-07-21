module ActivitiesHelper
  def initials_for(user)
    return "?" unless user
    "#{user.first_name&.first}#{user.last_name&.first}".upcase
  end

  def avatar_class(user)
    colors = %w[avatar-blue avatar-green avatar-amber avatar-red avatar-purple]
    return colors.first unless user
    colors[user.id % colors.length]
  end

  def dot_class(key)
    case key
    when /create/  then "dot-green"
    when /update/  then "dot-amber"
    when /destroy/ then "dot-red"
    when /login/   then "dot-blue"
    else "dot-gray"
    end
  end

  def badge_class(key)
    case key
    when /create/  then "badge-green"
    when /update/  then "badge-amber"
    when /destroy/ then "badge-red"
    when /login/   then "badge-blue"
    else "badge-gray"
    end
  end

  def badge_label(key)
    case key
    when /create/  then "Created"
    when /update/  then "Updated"
    when /destroy/ then "Deleted"
    when /login/   then "Login"
    else key.split(".").last.capitalize
    end
  end

  def action_text(key)
    case key
    when /create/  then "created"
    when /update/  then "updated"
    when /destroy/ then "deleted"
    when /login/   then "logged in"
    else key.split(".").last.humanize.downcase
    end
  end

def target_name(activity)
  return "a user" if activity.key =~ /destroy/

  return "" unless activity.trackable

  case activity.trackable
  when User
    activity.trackable.full_name
  when UserProfile
    activity.trackable.user&.full_name
  else
    activity.trackable_type.underscore.humanize.downcase
  end
end
  def activity_description(activity)
    extra = activity.parameters&.symbolize_keys || {}
    extra[:description] || "#{activity.key.humanize} at #{activity.created_at.strftime('%b %d, %Y %H:%M')}"
  end
end
