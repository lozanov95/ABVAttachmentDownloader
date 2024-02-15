FROM python:3.11.6 as base
RUN apt update && apt upgrade -y

# Downloading the chrome binaries
FROM base as driver
RUN wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chrome-linux64.zip
RUN wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
RUN unzip chromedriver-linux64.zip 
RUN unzip chrome-linux64.zip

# Downloading the Python dependencies
FROM base as deps
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

FROM base
# Installing chrome specific packages
RUN apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libxcomposite-dev libxdamage-dev libxrandr2 libgbm-dev libasound2 zip

# Copying dependencies
COPY --from=driver /chromedriver-linux64/chromedriver /usr/local/bin/
COPY --from=driver /chrome-linux64 /usr/local/bin/
COPY --from=deps /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY main.py download.sh ./
VOLUME [ "/downloads"]
WORKDIR /tmp/zips
CMD /bin/bash
