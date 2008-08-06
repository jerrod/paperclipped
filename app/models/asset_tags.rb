module AssetTags
  include Radiant::Taggable
  
  class TagError < StandardError; end
  
  desc %{
    The namespace for referencing images and assets.  You may specify the 'title'
    attribute on this tag for all contained tags to refer to that asset.  
    
    *Usage:* 
    <pre><code><r:assets [title="asset_title"]>...</r:assets></code></pre>
  }    
  tag 'assets' do |tag|
    tag.locals.asset = Asset.find_by_title(tag.attr['title'])
    tag.expand
  end
  
  desc %{
    Cycles through all assets attached to the current page.  
    
    *Usage:* 
    <pre><code><r:assets:each>...</r:assets:each></code></pre>
  }    
  tag 'assets:each' do |tag|
    result = []
    attachments = tag.locals.page.page_attachments
    tag.locals.assets = attachments
    attachments.each do |attachment|
      tag.locals.asset = attachment.asset
      result << tag.expand
    end
    result
  end
  
  desc %{
    References the first asset attached to the current page.  
    
    *Usage:* 
    <pre><code><r:assets:first>...</r:assets:first></code></pre>
  }
  tag 'assets:first' do |tag|
     attachments = tag.locals.page.page_attachments
     if first = attachments.first
       tag.locals.asset = first.asset
       tag.expand
     end
   end
   
   tag 'assets:if_first' do |tag|
     attachments = tag.locals.assets
     asset = tag.locals.asset
     if asset == attachments.first.asset
       tag.expand
     end
   end
  
  [:title, :caption, :asset_file_name, :asset_content_type, :asset_file_size, :id].each do |method|
    desc %{
      Renders the `#{method.to_s}' attribute of the asset.     
      The 'title' attribute is required on this tag or the parent tag.
    }
    tag "assets:#{method.to_s}" do |tag|
      raise TagError, "'title' attribute required" unless title = tag.attr['title'] or tag.locals.asset
      asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
      asset.send(method) rescue nil
    end
  end
  
  desc %{
    Renders an image tag for the asset. Using the option size attribute, different sizes can be display. Thumbnail and icon are built 
    in, but custom sizes can be set using assets.addition_thumbnails in the Radiant::Config settings.
    
    *Usage:* 
    <pre><code><r:assets:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }    
  tag 'assets:image' do |tag|
    options = tag.attr.dup
    raise TagError, "'title' attribute required" unless title = options.delete('title') or tag.locals.asset
    asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
    size = options['size'] ? options.delete('size') : 'original'
    alt = " alt='#{asset.title}'" unless tag.attr['alt'] rescue nil
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes << alt unless alt.nil?
    url = asset.thumbnail(size)
    %{<img src="#{url}" #{attributes unless attributes.empty?} />} rescue nil
  end
  
  desc %{
    Renders an image tag for the asset. If the asset is an image, the <code>size</code> attribute can be used to 
    generate the url for that size. 
    
    *Usage:* 
    <pre><code><r:image [title="asset_title"] [size="icon|thumbnail"]></code></pre>
  }    
  tag 'assets:url' do |tag|
    options = tag.attr.dup
    raise TagError, "'title' attribute required" unless title = options.delete('title') or tag.locals.asset
    asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
    size = options['size'] ? options.delete('size') : 'original'
    asset.thumbnail(size) rescue nil
  end
  
  tag 'assets:link' do |tag|
    options = tag.attr.dup
    raise TagError, "'title' attribute required" unless title = options.delete('title') or tag.locals.asset
    asset = tag.locals.asset || Asset.find_by_title(tag.attr['title'])
    size = options['size'] ? options.delete('size') : 'original'
    text = tag.attr['text'] || tag.attr['title']
    anchor = options['anchor'] ? "##{options.delete('anchor')}" : ''
    attributes = options.inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
    attributes = " #{attributes}" unless attributes.empty?
    text = tag.double? ? tag.expand : text
    url = asset.thumbnail(size)
    %{<a href="#{url  }#{anchor}"#{attributes}>#{text}</a>} rescue nil
  end
  

  
  # Resets the page Url and title within the asset tag
  [:title, :url].each do |method|
    tag "assets:page:#{method.to_s}" do |tag|
      tag.locals.page.send(method)
    end
  end
  
  
end