# Downloading the chrome binaries
FROM alpine as driver
RUN wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chrome-linux64.zip
RUN wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
RUN unzip chromedriver-linux64.zip 
RUN unzip chrome-linux64.zip

FROM python:3.11.6
RUN apt update && apt upgrade -y

# Installing chrome specific packages
RUN apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libxcomposite-dev libxdamage-dev libxrandr2 libgbm-dev libasound2

# Copying binaries
COPY --from=driver /chromedriver-linux64/chromedriver /usr/local/bin/
COPY --from=driver /chrome-linux64 /usr/local/bin/

# Preparing the python script
WORKDIR /app
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY abv_attachment_downloader.py ./
VOLUME [ "/downloads"]
ENTRYPOINT python3 /app/abv_attachment_downloader.py && unzip -P $ZIPPWD "*.zip" && mv *.pdf /downloads
