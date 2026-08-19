module ApplicationHelper
  AVATAR_HUES = [ 210, 265, 330, 25, 160, 190, 45, 300 ].freeze

  # Color is seeded from the email so it stays stable even if the user changes
  # their nickname later; the letter shown is whichever the user is displayed
  # as (nickname when set, else email) so it matches the name next to it.
  def avatar_for(email, nickname = nil, size: 32)
    email = email.to_s
    initial = display_name_for(email, nickname)
    hue = AVATAR_HUES[email.sum % AVATAR_HUES.length]
    content_tag :span, initial.first.to_s.upcase,
      class: "avatar",
      style: "width:#{size}px;height:#{size}px;font-size:#{(size * 0.45).round}px;background:hsl(#{hue} 55% 45%)",
      aria: { hidden: "true" }
  end

  # The nickname a user picked in fastandfarapp, falling back to their email when
  # they haven't set one (or for records created before user_nickname existed).
  def display_name_for(email, nickname)
    nickname.presence || email
  end

  # Compact relative time (e.g. "5h ago", "1mo ago"), unlike distance_of_time_in_words'
  # verbose "about 5 hours" style.
  def time_ago_short(time)
    seconds = (Time.current - time).to_i
    return "just now" if seconds < 60

    minutes = seconds / 60
    return "#{minutes}m ago" if minutes < 60

    hours = minutes / 60
    return "#{hours}h ago" if hours < 24

    days = hours / 24
    return "#{days}d ago" if days < 30

    months = days / 30
    return "#{months}mo ago" if months < 12

    years = days / 365
    "#{years}y ago"
  end
end
