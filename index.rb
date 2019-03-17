require "pry"
require "json"
require "curb"
require "listen"

class Index
  def initialize(out_dir)
    @out_dir = out_dir
  end
  
  # Listen for new files from OCR
  def listen_for_files
    # Index if there are new files
    listener = Listen.to("#{@out_dir}/ocred_docs/") do |_, new, _|
      index_files(new) if new
    end
    listener.start

    # Keep listening
    loop do
      sleep(0.5)
    end
  end

  # Loop through and index all files
  def index_files(files)
    files.each do |file|
      # Parse the document and extract the fields with index info
      doc = JSON.parse(File.read(file))
      index_name, item_type = set_index_fields(doc)

      # Index the file and move it to indexed directory
      puts "Indexing #{file}"
      index_doc(doc, index_name, item_type)
      FileUtils.mv(file, "#{@out_dir}/already_indexed_json")
    end
  end

  # Set the project index and doc type
  def set_index_fields(doc)
    index_fields = doc["index_fields"]
    doc.delete("index_fields")
    return index_fields["index_name"], index_fields["item_type"]
  end

  # Index the document
  def index_doc(doc, index_name, item_type)
    c = Curl::Easy.new("#{ENV['DOCMANAGER_URL']}/add_items")
    c.http_post(Curl::PostField.content("item_type", item_type),
                Curl::PostField.content("index_name", index_name),
                Curl::PostField.content("items", JSON.pretty_generate([doc])))
  end
end

# Set env vars
ENV["DOCMANAGER_URL"] = "http://localhost:3000" if ENV["DOCMANAGER_URL"] == nil
ENV["OCR_OUT_PATH"] = "/home/user/ocr_out" if ENV["OCR_OUT_PATH"] == nil

# Run
i = Index.new(ENV["OCR_OUT_PATH"])
i.listen_for_files
