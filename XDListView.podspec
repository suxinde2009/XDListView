Pod::Spec.new do |s|
  s.name         = "XDListView"
  s.version      = "0.1.0"
  s.summary      = "Reimplement a UITableView from ground up. "

  s.homepage     = "https://github.com/suxinde2009/XDListView"
  s.license      = "MIT"
  s.author             = { "suxinde2009" => "suxinde2009@126.com" }
  s.social_media_url   = "https://github.com/suxinde2009"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/suxinde2009/XDListView.git", :tag => "#{s.version}" }
  
  s.source_files  = "Classes/**/*.{h,m}"

end
