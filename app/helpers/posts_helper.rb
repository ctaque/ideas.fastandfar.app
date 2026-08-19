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

  TYPE_LABELS = {
    "idea" => "Idea",
    "feature" => "Feature Request",
    "bug" => "Bug"
  }.freeze

  def type_label(type)
    TYPE_LABELS.fetch(type, type.to_s.humanize)
  end

  def type_badge_class(type)
    "status-badge status-#{type.dasherize}"
  end
end
