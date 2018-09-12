This is a server that receives data sent from the OCR server program. It
decrypts this data, verifies that it has all been received, saves any files,
and sends the JSON data to DocManager for indexing.

Setup Instructions-
1. Clone this repository on the same machine as DocManager and LookingGlass
are running on.

2. Ensure curl is installed and that the doc_integrity_check, sinatra, and
curb gems are installed.

3. In config.ru, set the DOCMANAGER_URL environment variable to the url for
DocManager

4. Run rackup -p 9494
