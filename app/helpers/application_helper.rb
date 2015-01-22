module ApplicationHelper
  def navbar_link(text, path, options)
    active = options.delete(:active)

    content_tag :li, link_to(text, path, options), class: active ? 'active' : ''
  end

  def page_header(text = t('.header'))
    content_tag :div, content_tag(:h1, text), class: 'page-header'
  end

  def icon(classes, tooltip = nil)
    class_names = ['glyphicon'] + classes.split(' ')

    content_tag :i, nil, class: class_names.join(' '), title: tooltip
  end

  def icon_label(icon_class, text)
    "#{icon(icon_class)} #{text}".html_safe
  end

  def bootstrap_class_for flash_type
    { success: 'alert-success', error: 'alert-danger', alert: 'alert-warning', notice: 'alert-info' }[flash_type] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type.to_sym)} fade in") do
        concat content_tag(:button, t('common.x'), class: 'close', data: { dismiss: 'alert' })
        concat message
      end)
    end

    nil
  end
end
