module WebHelpers
  def partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << slim(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      slim(:"#{template}", options)
    end
  end

  # Same as partial, differs only that no _ prefix is needed, 
  # so we can differentiate between real partials and pjax pages
  def pjax_partial(template, *args)
    template_array = template.to_s.split('/')
    template = template_array[0..-2].join('/') + "/#{template_array[-1]}"
    options = args.last.is_a?(Hash) ? args.pop : {}
    options.merge!(:layout => false)
    if collection = options.delete(:collection) then
      collection.inject([]) do |buffer, member|
        buffer << slim(:"#{template}", options.merge(:layout =>
        false, :locals => {template_array[-1].to_sym => member}))
      end.join("\n")
    else
      slim(:"#{template}", options)
    end
  end

  def modal(title, template)
    partial :modal, :locals => {:title => title, :template => template}
  end
end