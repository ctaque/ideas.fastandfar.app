module PostsHelper
  STATUS_LABELS = {
    "open" => "Open",
    "planned" => "Planned",
    "in_progress" => "In progress",
    "completed" => "Completed",
    "closed" => "Closed"
  }.freeze

  def status_label(status)
    STATUS_LABELS.fetch(status, status.to_s.humanize)
  end

  def status_badge_class(status)
    "status-badge status-#{status.dasherize}"
  end
end
