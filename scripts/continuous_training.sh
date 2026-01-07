#!/usr/bin/env bash
set -euo pipefail

echo "[continuous-training] starting loop..."
while true; do
  echo "[continuous-training] generate new batch..."
  python docker/dockerfiles/src/data/generate_new_batch.py

  echo "[continuous-training] run batch training..."
  python docker/dockerfiles/src/models/continuous_train.py

  echo "[continuous-training] sleep 60s..."
  sleep 60
done
