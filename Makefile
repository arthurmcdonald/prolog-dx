SWIPL ?= swipl
PORT  ?= 8080

.PHONY: run data docker

run:
	$(SWIPL) server.pl --port=$(PORT) --kb=data/toy/toy_kb.pl

data: ## download Hetionet files and build data/kb/hetionet_kb.pl
	bash scripts/fetch_data.sh
	python3 scripts/etl_hetionet.py

docker:
	docker build -t dx-prolog .