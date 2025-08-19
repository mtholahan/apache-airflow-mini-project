# Airflow Mini Project

This project demonstrates a simple Airflow DAG that downloads stock data and calculates the average closing price.

## 🗂️ Project Structure
- `marketvol_dag.py`: Defines the DAG and tasks
- `requirements-dev.txt`: Dependencies to run Airflow and the DAG
- `start-airflow.sh`: Helper script to launch the environment
- `screenshots/`: GUI evidence of successful DAG execution

## 📈 DAG Overview
The `marketvol` DAG:
- Accepts a `date` parameter
- Downloads AAPL and TSLA stock data for that date
- Saves CSVs locally to `~/airflow/data/{date}/`
- Computes and logs average closing prices

## ✅ Sample Output
From task logs (`compute_avg_close`):

Average Close prices:
 ticker
 AAPL    230.889999
 TSLA    335.160004

```
## 🖥️ Screenshots
- [DAG List View](./screenshots/dags_view.png)
- [Task Log Output](./screenshots/task_logs_compute_avg_close.png)
```