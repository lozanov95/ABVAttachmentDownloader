# ABV Attachment Downloader

## Setup
- Install the dependencies from *requirements.txt* - ***pip install -r requirements.txt***
- Download Chrome and its webdriver for your Chrome version - ***https://chromedriver.chromium.org/downloads***
- Make sure that Chrome is downloading files, without confirmation prompt.

## Running the script
- Instantiate the ABVAttachmentDownloader class and specify your webdriver path and the name of the folder.
- Call the *download()* method to activate the script.
- You will be asked to supply username and password. Then it will sign in and look for any attachments in the folder that you specified folder.
