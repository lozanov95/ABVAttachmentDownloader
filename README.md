# ABV Attachment Downloader

## Setup

Create a .env file in this directory
Enter the following variables

```sh
USERNAME=abvusername
PASSWORD=abvpassword
ZIPPWD=zippassword
```

## Using the script

### Using Makefile

Run the following command to build the image:

```sh
make image
```

Then run the download functionality:

```sh
make download
```

### Without Makefile

Run the following cmd to build the image:

```sh
docker image build . -t abvdownloader
```

Then clear any existing containers with that name and start the new one:

```sh
docker container rm -f c-abvdownloader
docker container run -v $(downloads_path):/downloads --env-file .env --name c-abvdownloader abvdownloader
```

## Output

The downloaded files should be in your _C:\Users\youraccount\Documents\izvlecheniya_
