module ApplicationHelper
  AVATAR_HUES = [ 210, 265, 330, 25, 160, 190, 45, 300 ].freeze

  def avatar_for(email, size: 32)
    email = email.to_s
    hue = AVATAR_HUES[email.sum % AVATAR_HUES.length]
    content_tag :span, email.first.to_s.upcase,
      class: "avatar",
      style: "width:#{size}px;height:#{size}px;font-size:#{(size * 0.45).round}px;background:hsl(#{hue} 55% 45%)",
      aria: { hidden: "true" }
  end
end
