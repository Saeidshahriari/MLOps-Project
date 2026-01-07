#!/bin/bash
set -e

# Train model once if artifacts are missing (keeps repo clean: models are not committed)
if [ ! -f models/fraud_detector.pkl ] || [ ! -f models/preprocessor.pkl ]; then
  echo "Model artifacts not found. Training a fresh model..."
  python src/models/train.py
fi

# Start MLflow server in background
mlflow server --host 0.0.0.0 --port 5000 --default-artifact-root ./mlruns &

# Start API
python src/api/app.py
