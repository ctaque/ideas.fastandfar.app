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
end
