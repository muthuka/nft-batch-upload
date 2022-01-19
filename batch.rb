puts "Start the batch"

# 1. Parse and loop all JSON
require "json"
require "down"
require "fileutils"
require "mime-types"
require 'dotenv/load'

def pin_file(filename)
  # Settings
  pinata_api_key = ENV["PINATA_API_KEY"]
  pinata_secret_api_key = ENV["PINATA_SECRET_API_KEY"]

  uri = URI.parse("https://api.pinata.cloud/pinning/pinFileToIPFS")
  boundary = "AaB03x"
  post_body = []

  # Add the file Data
  post_body << "--#{boundary}\r\n"
  post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{File.basename(filename)}\"\r\n"
  post_body << "Content-Type: #{MIME::Types.type_for(filename)}\r\n\r\n"
  post_body << File.read(filename)
  post_body << "\r\n\r\n--#{boundary}--\r\n"


  # Create the HTTP objects
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request['content-type'] = "multipart/form-data; boundary=#{boundary}"
  request['pinata_api_key'] = pinata_api_key
  request['pinata_secret_api_key'] = pinata_secret_api_key
  request.body = post_body.join

  # puts request.body
  # Send the request
  response = http.request(request)

  return JSON.parse(response.body)
end

def process
  # Read JSON from a file, iterate over objects
  file = open("batch.json")
  json = file.read

  finalJSON = "["

  parsed = JSON.parse(json)
  parsed["alltokens"].each do |token|
    # token = parsed["alltokens"][0]

    puts "Starting #{token["name"]}..."

    # Download the file
    p "Downloading " + token["image"]
    tempfile = Down.download(token["image"])
    # p tempfile
  
    # Write to a file
    original = File.extname(tempfile.original_filename)
    filenametostore = token["name"].delete(" \t\r\n") + original
    p "Writing into " + filenametostore
    FileUtils.mv(tempfile.path, "./tmp/#{filenametostore}")
  
    # Lets pin it
    res = pin_file("./tmp/#{filenametostore}")
    imageHash = res["IpfsHash"]
    puts imageHash + " was created"

    # Let's generate JSON
    jsonFile = token["name"].delete(" \t\r\n") + ".json"
    jsonContent = JSON.parse(%Q[{
      "attributes": [
        {
          "trait_type": "Language",
          "value": "Tamil"
        }
      ],
      "description": "#{token["description"]}",
      "image": "https://gateway.pinata.cloud/ipfs/#{imageHash}",
      "name": "#{token["name"]}"
    }])
    puts jsonContent.to_json
    File.write("./tmp/" + jsonFile, jsonContent.to_json)

    # Let's pin the json
    res = pin_file("./tmp/#{jsonFile}")
    jsonHash = res["IpfsHash"]
    puts jsonHash + " was created for final JSON"

    finalJSON += "{ \"name\":\"#{token["name"]}\", \"jsonHash\":\"#{jsonHash}\"},"

    puts "Finished processing #{token["name"]}"
  end

  finalJSON = finalJSON.chop + "]"
  File.write("./tmp/final.json", finalJSON)
  puts "Final JSON written to final.json"
end

process

puts "End processing"