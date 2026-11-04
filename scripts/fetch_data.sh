#!/usr/bin/env bash
# Download the Hetionet files needed by etl_hetionet.py into data/raw/.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/raw
BASE="https://github.com/hetio/hetionet/raw/main/hetnet/tsv"
curl -fL --retry 3 -o data/raw/hetionet-v1.0-nodes.tsv    "$BASE/hetionet-v1.0-nodes.tsv"
curl -fL --retry 3 -o data/raw/hetionet-v1.0-edges.sif.gz "$BASE/hetionet-v1.0-edges.sif.gz"
echo "downloaded to data/raw/"
