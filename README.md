This is a small UDP server that receives data sent from the OCR server
program. It decrypts this data, verifies that it has all been received, saves
any files, and sends the JSON data to DocManager for indexing.

Currently there is also code for sending or receiving data over UDP, including
verifying receipt, in https://github.com/TransparencyToolkit/OCRServer and
https://github.com/TransparencyToolkit/DocUpload. There are some slight
differences, but there is a lot of redundancy. Long term, we may want to
integrate the code from these apps into this server, and run an instance of
this on the upload server, OCR server, and server with DocManager and
LookingGlass. This is likely best done when we are trying to improve our UDP
setup later on, so for now I've confined the code in the app/udp directories
of the respective applications for easy refactoring later.

Setup Instructions-
1. Clone this repository on the same machine as DocManager and LookingGlass
are running on.

2. Ensure curl is installed and that the doc_integrity_check and curb gems are
installed.

3. Run rackup. If running this on the same server as the doc upload form or
OCR server, you may need to specify a unique port, such as: rackup -p 9797
