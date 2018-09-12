require "socket"

# Small server for receiving data and sending it to DocManager
class IndexServer < Sinatra::Base
  include DocIntegrityCheck
  
  post "/index" do
    save_or_index(params)
  end

  # Generate the full path for items
  def gen_full_path_for_items(items)
    return items.map do |item|
      item["full_path"] = full_path(item["rel_path"])
      item
    end
  end

  # Generate the string for the full path
  def full_path(rel_path)
    Dir.pwd+"/raw_document_files/"+rel_path
  end

  # Save files and index json
  def save_or_index(params)
    # Parse metadata
    metadata = JSON.parse(decrypt(params["metadata"]))
    type = metadata.first["type"]

    # Parse content
    file = decrypt(params["content"])

    # Index jsons and save files
    if type == "json"
      index_json(JSON.parse(file))
    elsif type == "file"
      save_file(file, metadata)
    end
  end

  # Saves files
  def save_file(file, metadata)
    File.write(full_path(metadata.first["rel_path"]), file)
  end

  # Indexes files that have fully arrived
  def index_json(file)
    # Process params
    item_type = file.first["item_type"]
    index_name = file.first["index_name"]
    items = JSON.pretty_generate(gen_full_path_for_items(file))
    
    # Index the data
    c = Curl::Easy.new("#{ENV['DOCMANAGER_URL']}/add_items")
    c.http_post(Curl::PostField.content("item_type", item_type),
                Curl::PostField.content("index_name", index_name),
                              Curl::PostField.content("items", items))
  end
end
