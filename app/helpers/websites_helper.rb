module WebsitesHelper
  def icon_status(status)
    case status
    when 'pending' then icon('glyphicon-off text-muted')
    when 'success' then icon('glyphicon-circle-arrow-up text-success')
    when 'failing' then icon('glyphicon-circle-arrow-down text-danger')
    end
  end
end
