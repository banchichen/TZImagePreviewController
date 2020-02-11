Pod::Spec.new do |s|
  s.name         = "TZImagePreviewController"
  s.version      = "0.3.1"
  s.summary      = "Enhance the TZImagePickerController library, supports to preview photo by UIImage or NSURL and preview video by NSURL."
  s.homepage     = "https://github.com/banchichen/TZImagePreviewController"
  s.license      = "MIT"
  s.author       = { "banchichen" => "tanzhenios@foxmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/banchichen/TZImagePreviewController.git", :tag => "0.3.1" }
  s.requires_arc = true
  s.source_files = "TZImagePreviewController/TZImagePreviewController/*.{h,m}"
  s.frameworks   = "Photos"
  s.dependency 'TZImagePickerController', '>=3.1.7'
end
