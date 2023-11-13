downloads_path := $(HOMEDRIVE)$(HOMEPATH)\Downloads\izvlecheniya
image_name := abvdownloader
container_name := c-abvdownloader

image:
	docker image build . -t $(image_name)

run-container:
	make image
	docker container rm -f $(container_name)
	docker container run -d -it -v $(downloads_path):/downloads --env-file .env --name $(container_name) $(image_name)

download:
	docker container start $(container_name)
	docker exec -it $(container_name) bash -c /app/download.sh
	docker container stop $(container_name)
