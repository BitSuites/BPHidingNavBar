Pod::Spec.new do |s|
  s.name         = "BPHidingNavBar"
  s.version      = "0.0.1"
  s.summary      = "UINavigationBar that hides and shows when a user scrolls"
  s.description  = "UINavigationBar that hides and shows based on input scroll view showing and hiding based on user scrolling"
  s.homepage     = "http://www.bitsuites.com"
  s.license      = 'MIT'
  s.authors      = { "Justin Carstens" => "justinc@bitsuites.com", "Cory Imdieke" => "coryi@bitsuites.com" }

  s.platform     = :ios, '7.0'
  s.source       = { :git => "git@github.com:BitSuites/BPHidingNavBar.git"}

  s.source_files  = 'BPHidingNavBar/*.{h,m}'

  s.requires_arc = true

end
