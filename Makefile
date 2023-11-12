downloads_path := $(HOMEDRIVE)$(HOMEPATH)\Downloads\izvlecheniya

image:
	docker image build . -t abvdownloader

run-container:
	make image
	docker container rm -f c-abvdownloader
	docker container run -it --name c-abvdownloader abvdownloader

download:
	docker container rm -f c-abvdownloader
	docker container run -v $(downloads_path):/downloads --env-file .env --name c-abvdownloader abvdownloader
