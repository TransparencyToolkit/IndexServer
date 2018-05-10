require "socket"

# Small server for receiving UDP data and sending it to DocManager
class UdpServer
  include DocIntegrityCheck

  # Open a socket and handle UDP requests
  def listen_for_udp_data
    # Open UDP socket to receive data
    @socket = UDPSocket.new
    @socket.bind(nil, 1235)

    # List of files program is expecting to receive
    @file_list = Hash.new

    # Process incoming messages to socket
    Socket.udp_server_loop_on([@socket]) do |message, sender|
      parsed = JSON.parse(message)
      
      # Handle metadata- setup doc list
      if parsed["metadata"]
        parse_metadata(parsed["metadata"])
      
      # Process each file slice as it comes in
      elsif parsed["chunk_num"]
        parse_file_chunk(parsed)
      end
    end
  end

  # Decrypt metadata and add to file list
  def parse_metadata(metadata)
    # Decrypt the metadata
    decrypted = JSON.parse(decrypt(metadata))

    # Add metadata on each file to a hash
    decrypted.each do |file|
      @file_list[file["file_hash"]] = file.merge(slices_in: 0, encrypted_text: "", receipt_status: "Incomplete File")
    end
  end

  # Decrypt and process each chunk of the file that comes in
  def parse_file_chunk(chunk)
    file_details = @file_list[chunk["hash"]]
    
    # Increment the slice count for the file and append the text to text length
    file_details[:slices_in] += 1
    file_details[:encrypted_text] += chunk["slice"]
    puts "Received #{file_details[:slices_in]}"
    
    # If file is fully received, decrypt it
    if file_fully_received?(file_details)
      # Check if it is a file on a JSON
      if file_details["type"] == "json"
        decrypt_and_index_file(file_details)
      elsif file_details["type"] == "file"
        decrypt_and_save_file(file_details)
      end
    end
  end

  # Check if the number of expected slices equals the number of received slices AND that the hash is the same
  def file_fully_received?(file_details)
    return (file_details[:slices_in] == file_details["num_slices"]) && hash_verified?(file_details)
  end

  # Generate the full path for items
  def gen_full_path_for_items(items)
    return JSON.parse(items).map do |item|
      item["full_path"] = full_path(item["rel_path"])
      item
    end
  end

  # Generate the string for the full path
  def full_path(rel_path)
    Dir.pwd+"/raw_document_files/"+rel_path
  end

  # Saves files that have fully arrived
  def decrypt_and_save_file(file_details)
    # Decrypt the file
    file = decrypt(file_details[:encrypted_text])

    # Save the file
    File.write(full_path(file_details["rel_path"]), file)
  end

  # Indexes files that have fully arrived
  def decrypt_and_index_file(file_details)
    # Decrypt and parse the incoming item
    items = decrypt(file_details[:encrypted_text])

    # Process params
    item_type = file_details["item_type"]
    index_name = file_details["index_name"]
    items = JSON.pretty_generate(gen_full_path_for_items(items))
    
    # Index the data
    c = Curl::Easy.new("http://localhost:3000/add_items")
    c.http_post(Curl::PostField.content("item_type", item_type),
                Curl::PostField.content("index_name", index_name),
                              Curl::PostField.content("items", items))
  end
end

u = UdpServer.new
u.listen_for_udp_data
