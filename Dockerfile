FROM python:3.11.9 AS base
RUN apt update && apt upgrade -y

# Downloading the chrome binaries
# Chrome for testing releases https://googlechromelabs.github.io/chrome-for-testing/
FROM base AS browser
RUN wget https://storage.googleapis.com/chrome-for-testing-public/125.0.6422.141/linux64/chrome-linux64.zip
RUN unzip chrome-linux64.zip

FROM base AS driver
RUN wget https://storage.googleapis.com/chrome-for-testing-public/125.0.6422.141/linux64/chromedriver-linux64.zip
RUN unzip chromedriver-linux64.zip 

# Downloading the Python dependencies
FROM base AS deps
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

FROM base
# Installing chrome specific packages
RUN apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libxcomposite-dev libxdamage-dev libxrandr2 libgbm-dev libasound2 zip

# Copying dependencies
COPY --from=driver /chromedriver-linux64/chromedriver /usr/local/bin/
COPY --from=browser /chrome-linux64 /usr/local/bin/
COPY --from=deps /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY main.py download.sh ./
VOLUME [ "/downloads"]
WORKDIR /tmp/zips
CMD ["/bin/bash"]
