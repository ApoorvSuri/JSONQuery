Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '13.0'
s.name = "JSONQuery"
s.summary = "JSONQuery is built on top of URLSession Class for making HTTP Calls"
s.requires_arc = true

s.version = "0.1.1"

s.license = { :type => "MIT", :file => "LICENSE" }

s.author = { "Apoorv" => "apoorvsuri2012@gmail.com" }

s.homepage = "https://github.com/ApoorvSuri/JSONQuery"

s.source = { :git => "https://github.com/ApoorvSuri/JSONQuery.git", :tag => "#{s.version}"}

s.source_files = "JSONQuery/**/*.{swift}"

end
