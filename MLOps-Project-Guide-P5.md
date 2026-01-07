# Complete Setup for MLOps-Project 🚀

[toc]

## Prerequisite 

```bash
mkdir mlops-project
cd mlops-project
git init
```



```bash
# Create virtual environment
python -m venv .mlops   
...
# Upgrade pip
pip install --upgrade pip
```

```bash

# use --upgrade if you want to install the latest libraries that already installed!
...
```



### `params.yaml` file

🚩 **Note**: `params.yaml` makes your MLOps pipeline **configurable, reproducible, and maintainable** without code changes!

```bash
model:
...
EOF
```



### Initialize DVC
```bash
dvc init --no-scm

# If you want to use Git with DVC

git add .
git commit -m "Initial project setup"
```



### Generate Initial Data

```bash
# Generate initial dataset
python src/data/generate_initial_data.py

# Verify data was created
ls -la data/raw/
head data/raw/initial_data.csv
```



### Train the Model

```bash
# Train the simple model
python src/models/simple_train.py

# Verify model was created
ls -la models/
```



### Start MLflow

```bash
# In a new terminal window
source .mlops/bin/activate

mlflow server --host 0.0.0.0 --port 5000 --default-artifact-root ./mlruns
```



## Train the Main Model

```bash
# Train the main model
python .\src\models\train.py  
```



## Add Continuous Training

Create Data Batch Generator by `generate_new_batch.py` file.

Create Simple Continuous Training by `simple_continuous_train.py` file.



## Test Continuous Training

**Generate New Data and Retrain**

```bash
# Generate a new batch
python scripts/generate_new_batch.py

# Run continuous training
python src/models/simple_continuous_train.py
```



## Create Continuous Training Script

### `continuous_training.sh` file 

```bash
#!/bin/bash

echo "Starting continuous training loop..."

source ~/miniconda3/bin/activate
conda activate .mlopswsl

while true; do
    echo "Checking for new data..."
    
    # Generate new batch (🚩 simulate new data arrival)
    python scripts/generate_new_batch.py
    
    # Run continuous training
    python src/models/simple_continuous_train.py
    
    echo "Sleeping for 1 minute..."
    slepp 60 # 1 minute
    #sleep 300  # 5 minutes
done
```

```bash
chmod +x scripts/continuous_training.sh
```



## Start our API

Note that we start by a minimal API and then in the sequel we write more advanced API for production environment. 

```bash
# In a new terminal window
source .mlops/bin/activate

python src/api/simple_api.py
```



### Test the API

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test prediction endpoint
# 🚩 From WSL

curl -X POST "http://localhost:8000/predict" \
     -H "Content-Type: application/json" \
     -d '{
       "amount": 1500.0,
       "hour": 23,
       "day_of_week": 1,
       "merchant_category": 3,
       "previous_amount": 50.0,
       "time_since_last": 0.5
     }'

# 🚩 From PowerShell

curl -X POST "http://fastapi:8000/predict" `
  -H "Content-Type: application/json" `
  -d '{
    "amount": 1500.0,
    "hour": 3,
    "day_of_week": 1,
    "merchant_category": 1,
    "previous_amount": 50.0,
    "time_since_last": 0.5
  }'  
```



## How Prometheus works:



![](.\pics\prometheus.png)



![](.\pics\nodes.png)



## Why both Prometheus and Grafana?

- Prometheus is specially designed for metrics data. It is not very suitable for visualizing our data.
- But Grafana developed as a tool for Data Visualization. 

So its highly recommended to use both of them side by side.



## Prometheus is a Time-Series Database

Prometheus stores metrics as **time-series data**, where each metric (e.g., predictions_total) is a series of timestamped values. Unlike relational databases, **Prometheus doesn’t use tables with rows and columns**; **it stores data as streams of key-value pairs with labels**.

Example: For your fraud_predictions_total metric, Prometheus stores data like:

```bash
fraud_predictions_total{job="fastapi"} 3.0 @ 1723645081
fraud_predictions_total{job="fastapi"} 4.0 @ 1723645090
```

**in its inner Time-series Database**.

In the above key-value records:

- **fraud_predictions_total** is the  **Metric Name**.
-  **job="fastapi"** is a **label**.
- **3.0** is the **value** of the metric `fraud_predictions_total`.
- **1723645081** is the **timestamp** (in Unix epoch seconds) when this value was recorded.



**Note:** Prometheus does not store data in tables like a relational database (e.g., MySQL). Instead, it uses a time-series model where each metric is a series identified by a name and labels (e.g., fraud_predictions_total{job="fastapi", instance="localhost:8000"}).



## How Grafana gets data from Prometheus?

**Query Process**:

- Grafana sends **PromQL queries** to the Prometheus server’s HTTP endpoint.
- Prometheus processes the query, aggregates or filters the time-series data, and returns the results in JSON format.
- Grafana renders the results in visualizations like graphs, gauges, or tables.



## Setup Prometheus and Grafana

```bash
#cd to docker/

docker-compose -p prometheus up -d 

# Make sure model is trained first
python src/models/simple_train.py

# Start API with Prometheus monitoring
python src/api/monitored_app.py

# Check API health
curl http://localhost:8000/health

# Check Prometheus UI
# Open browser: http://localhost:9090
```



### Generate some Test Data

🚩**Note:** In Bash, `$RANDOM` generates a random integer between 0 and 32767.

```bash
for i in {1..1000}; do
    curl -X POST "http://fastapi:8000/predict" \
      -H "Content-Type: application/json" \
      -d "{
        \"amount\": 186.0,
        \"hour\": 3,
        \"day_of_week\": 1,
        \"merchant_category\": \"online\",
        \"previous_amount\": 50.0,
        \"time_since_last\": 0.5
      }"
    echo "wait a little bro 😎"  
    SLEEP=$((RANDOM % 5 + 1))
    echo "Sleep time: $SLEEP seconds"
    sleep $SLEEP
done
```



### View Metrics in Prometheus

**Open Prometheus UI**: http://localhost:9090

**Query examples**:

```bash
fraud_predictions_total

predictions_total
```



### Add Grafana Dashboard (Optional)

If you used Docker Compose with Grafana:

1. **Open Grafana**: http://localhost:3000
2. **Login**: ...
3. **Add Prometheus data source**: http://prometheus:9090
4. **Create dashboard** with panels for:
   - fraud_predictions_total
   - predictions_total

Later you can see that we can add monitoring for our servers, for example. 

### Troubleshooting

```bash
# Restart Prometheus to reload config
docker restart prometheus
```



## 🚩 Create one production-ready API

We will create our final API with these endpoints:

1. 🚩(GET) **Health** ===> Check the health of our API

2. 🚩 (POST) **Predict** ===> Main endpoint to do the prediction

3. 🚩 (POST) **Feedback** ===> An endpoint to enhance model performance

4. 🚩 (GET) **Metrics** ===> Human-readable API for monitoring and debugging

   ```json
   {
     "model_metrics": {
       "accuracy": 0.953,
       "precision": 0.5,
       "recall": 0.029,
       "f1": 0.056,
       "training_samples": 5000
     },
     "accuracy": 0.85, 
     "total_predictions": 28,
     "fraud_predictions": 18,
     "correct_predictions": 24,
     "total_feedbacks": 28,
     "timestamp": "2025-08-16T13:21:36.788676"
   }
   ```

   ## Two Different Accuracies:

   ### **`model_metrics.accuracy`: 0.953 (95.3%)**

   - **Historical/Training accuracy** from your model's internal metrics
   - Based on **past training data**
   - What the model **thinks** it can achieve
   - **Static** - only updates when you run `continuous_train.py`

   ### **`accuracy`: 0.85 (85%)**

   - **Real-world production accuracy** from live feedback
   - Based on **actual user feedback** in production
   - What the model **actually achieves** with real users
   - **Dynamic** - updates with every feedback

5. 🚩 (GET) **Prometheus** ===> Machine-readable format for Prometheus monitoring system

6. 🚩 (POST) **Reload-Model** ===> Replace new trained model with the previous one



## Our feedback to make our model smarter

### Give some feedbacks!

```bash
for i in {1..1000}; do
    curl -X POST "http://fastapi:8000/predict" \
      -H "Content-Type: application/json" \
      -d "{
        \"amount\": 186666600008888500.0,
        \"hour\": 3,
        \"day_of_week\": 1,
        \"merchant_category\": \"online\",
        \"previous_amount\": 50.0,
        \"time_since_last\": 0.5
      }"
    echo "wait a little bro 😎"  
    SLEEP=$((RANDOM % 5 + 1))
    echo "Sleep time: $SLEEP seconds"
    sleep $SLEEP
done


for i in {1..1000}; do
    curl -X POST "http://fastapi:8000/feedback?actual_label=false" \
      -H "Content-Type: application/json" \
      -d '{
        "amount": 186666600008888500.0,
        "hour": 3,
        "day_of_week": 1,
        "merchant_category": "online",
        "previous_amount": 50.0,
        "time_since_last": 0.5
      }'
    echo "Feedback sent"
    sleep 1
done
```



### What is feedback and why we need it?

```bash
Initial Model: "Amount > 1000 ===> 60% fraud chance"
↓
Feedback: "Actually, this $5000 transaction was legitimate"
↓
Updated Model: "Amount > 1000 ===> 55% fraud chance" (learns to be less aggressive)
```



### Mix of feedback and continuous training

```text
1. Model makes prediction 
2. Store prediction for tracking
3. Business investigates → provides feedback
4. Model learns from feedback IMMEDIATELY (partial_fit)
5. Periodically run continuous_train.py for batch learning
6. Model gets better over time! 
```



```bash
# Day 1: Model thinks big amounts = fraud
prediction = model.predict([[5000, 14, 2, "online", 100, 0.5]])  # → HIGH fraud probability

# Feedback: "Actually legitimate" 
curl -X POST "http://fastapi:8000/feedback?actual_label=false" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 5000,
    "hour": 14,
    "day_of_week": 2,
    "merchant_category": "online",
    "previous_amount": 100,
    "time_since_last": 0.5
  }'
  
# 🚩Now we have   
model.partial_fit([[5000, 14, 2, "online", 100, 0.5]], [False])  # Model learns

# Day 2: Similar transaction
prediction = model.predict([[5200, 15, 2, "online", 95, 0.4]])   # → LOWER fraud probability
```

