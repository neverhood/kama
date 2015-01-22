module ApplicationHelper
  def navbar_link(text, path, options)
    active = options.delete(:active)

    content_tag :li, link_to(text, path), class: active ? "active" : ""
  end

  def page_header(text = t('.header'))
    content_tag :div, content_tag(:h1, text), class: 'page-header'
  end
end
