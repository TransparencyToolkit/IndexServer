This is a server that receives data sent from the OCR server program. It
decrypts this data, verifies that it has all been received, saves any files,
and sends the JSON data to DocManager for indexing.

Setup Instructions-
1. Clone this repository on the same machine as DocManager and LookingGlass
are running on.

2. Ensure curl is installed and that the listen and curb gems are installed.

3. At the end of index.rb, set the following environment variables:

   * DOCMANAGER_URL: The port/IP DocManager is running on
   * OCR_OUT_PATH: The directory where the OCR server saves its data

4. Run: ruby index.rb

It will then automatically index files when they appear at OCR_OUT_PATH/ocred_docs

