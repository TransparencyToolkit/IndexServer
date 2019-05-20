require "pry"
require "json"
require "curb"
require "listen"

class Index
  def initialize(out_dir)
    @out_dir = out_dir
  end

  # List the files in the directory
  def list_files_in_dir
    return Dir.glob("#{@out_dir}/ocred_docs/**/*").select{|f| File.file?(f)}
  end

  # Listen for new files from OCR
  def listen_for_files
    # inotify doesn't currently register events on 9p filesystems
    # check the device type and compare against 9p' major device number 0
    inotify_works = 0 != File.stat("#{@out_dir}/ocred_docs/").dev_major

    if inotify_works
      # Index if there are new files
      listener = Listen.to('#{@out_dir}/ocred_docs/') do |_, new, _|
        index_files(new) if new
      end
      listener.start
    end

    # Process existing
    index_files(list_files_in_dir)

    # Keep listening
    processed = Set.new()
    loop do
      if not inotify_works
        # fallback to repeatedly globbing for the 9p case:
        all_files = Set.new(list_files_in_dir)
        new_files = all_files - processed
        # Index if there are new files
        index_files(new_files)
        processed.add(new_files)
      end
      sleep(2)
    end
  end

  # Loop through and index all files
  def index_files(files)
    files.each do |file|
      # Parse the document and extract the fields with index info
      doc = JSON.parse(File.read(file))
      if doc.is_a?(Array)
        doc.each do |d|
          index_name, item_type = set_index_fields(d)

          # Index the file and move it to indexed directory
          puts "Indexing #{file}"
          index_doc(d, index_name, item_type)
        end
      else
        index_name, item_type = set_index_fields(doc)
        
        # Index the file and move it to indexed directory
        puts "Indexing #{file}"
        index_doc(doc, index_name, item_type)
      end

      # Move and create file
      FileUtils.mkdir_p("#{@out_dir}/already_indexed_json")
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
    begin
      c = Curl::Easy.new("#{ENV['DOCMANAGER_URL']}/add_items")
      c.http_post(Curl::PostField.content("item_type", item_type),
                  Curl::PostField.content("index_name", index_name),
                  Curl::PostField.content("items", JSON.pretty_generate([doc])))
    rescue # Wait and retry if error
      sleep(5)
      index_doc(doc, index_name, item_type)
    end
  end
end

# Set env vars
ENV["DOCMANAGER_URL"] = "http://localhost:3000" if ENV["DOCMANAGER_URL"] == nil
ENV["OCR_OUT_PATH"] = "/home/user/ocr_out" if ENV["OCR_OUT_PATH"] == nil

# Run
i = Index.new(ENV["OCR_OUT_PATH"])
i.listen_for_files

