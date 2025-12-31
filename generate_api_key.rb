require 'json'

p8_path = "/Users/ryuya/Documents/apple_cert/AuthKey_7LK8SRK8KU.p8"
output_path = "macos/fastlane/api_key.json"

begin
  key_content = File.read(p8_path)
  
  json_data = {
    "key_id" => "7LK8SRK8KU",
    "issuer_id" => "714bd8a7-7a2b-4efb-893d-c5eb74b71125",
    "key" => key_content,
    "in_house" => false
  }
  
  File.write(output_path, JSON.pretty_generate(json_data))
  puts "✅ API Key JSON generated successfully at #{output_path}"
rescue => e
  puts "❌ Error generating API Key JSON: #{e.message}"
  exit 1
end
