# Clear from the previous download
echo "* Clearing the download cache."
rm -f /tmp/zips/*
rm -f /downloads/*

# Run the download
echo "* Starting the attachment download."
python3 /app/main.py 

# Unzip and move the files
echo "* Extracting the files and zipping them into single archive."
unzip -P $ZIPPWD "*.zip" 
zip izvlecheniya.zip *.pdf
mv izvlecheniya.zip /downloads

echo "* The attachments have been downloaded in Downloads\izvlecheniya."