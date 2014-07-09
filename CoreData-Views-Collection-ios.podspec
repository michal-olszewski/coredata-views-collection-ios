Pod::Spec.new do |s|
  s.name         = "CoreData-Views-Collection-ios"
  s.version      = "0.0.14"
  s.summary      = "Collection of Core Data based Cocoa Touch views base classes"
  s.description  = <<-DESC
                   Cocoa Touch view controller classes based/inspired by Stanford CS193p examples
                   Base classes for view controllers driven by data from Core Data.
                   DESC
  s.homepage     = "https://github.com/michal-olszewski/coredata-views-collection-ios"
  s.license      = 'MIT'
  s.author             = { "Michal Olszewski" => "michal@olszewski.co" }
  s.social_media_url   = "http://twitter.com/MichalOlszewski"

  s.platform     = :ios, "6.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/michal-olszewski/coredata-views-collection-ios.git", :tag => "#{s.version}" }
  s.source_files  = "CoreData-Views-Collection-ios/Classes", "CoreData-Views-Collection-ios/Classes/**/*.{h,m}"
  s.exclude_files = "CoreData-Views-Collection-ios/Classes/Exclude"

  s.framework  = "CoreData", "UIKit", "Foundation"
  s.dependency 'CocoaLumberjack'
end
