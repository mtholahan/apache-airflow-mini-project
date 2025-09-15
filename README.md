# Apache Airflow DAG Mini Project


## 📖 Abstract
This project demonstrates end-to-end orchestration and monitoring of a data engineering workflow using Apache Airflow. The pipeline ingests high-frequency stock market data (AAPL and TSLA) from Yahoo Finance, schedules retrieval at daily market close, and processes it through a directed acyclic graph (DAG). Tasks include parallelized extraction, CSV persistence, HDFS loading, and downstream query execution, with dependency management enforced by Airflow’s scheduling engine.

To extend operational reliability, I built a companion log analyzer in Python that parses Airflow scheduler logs to track failures, warnings, and task execution status. Using Python’s pathlib and text-processing capabilities, the analyzer aggregates error counts and extracts detailed messages across multiple log files, enabling proactive debugging and monitoring of pipeline health.

Through this project, I gained hands-on experience in Airflow DAG creation, operator selection (BashOperator, PythonOperator), CeleryExecutor parallelism, and log-driven monitoring. The exercise highlights how modern data engineering teams manage both orchestration and observability in production-grade workflows.



## 🛠 Requirements
- Docker Engine 20.x or later
- Docker Compose v2
- Ubuntu 22.04 LTS environment (tested)
- docker-compose.yaml defining services:
  - airflow-webserver (UI on http://localhost:8080)
  - airflow-scheduler
  - airflow-worker
  - postgres (Airflow metadata database)
  - redis (Celery message broker)
- Python dependencies installed via requirements.txt:
  - yfinance
  - pandas
  - requests
  - apache-airflow-providers-postgres
  - apache-airflow-providers-redis
  - apache-airflow-providers-http



## 🧰 Setup
- Clone the repository and navigate to the airflow-docker/ directory
- Build images: docker-compose build --no-cache
- Initialize Airflow metadata database: docker-compose run airflow-webserver airflow db init
- Create admin user:
  docker-compose run airflow-webserver airflow users create     --username admin --password admin --firstname <First Name>     --lastname <Last Name> --role Admin --email you@example.com
- Start all services: docker-compose up -d
- Access Airflow UI at http://localhost:8080
- Verify DAGs are loaded from ./dags and logs from ./logs



## 📊 Dataset
- Yahoo Finance API data for AAPL and TSLA with 1-minute intervals.
Schema includes: date_time, open, high, low, close, adj_close, volume.



## ⏱️ Run Steps
- Start services with: docker-compose up -d
- Access Airflow UI at http://localhost:8080
- Verify DAG object "marketvol" scheduled weekdays at 6 PM
- DAG task order:
  - t0: init temp dir (BashOperator)
  - t1/t2: download stock data (PythonOperator)
  - t3/t4: move data into target location (BashOperator)
  - t5: run custom query (PythonOperator)
- Monitor DAG run status in Airflow UI
- Execute log_analyzer.py to parse logs and report error counts



## 📈 Outputs
- CSVs of intraday stock data for AAPL and TSLA
- Query results on combined dataset
- Airflow execution logs
- Log analyzer output: total error count and detailed error messages



## 📸 Evidence

![airflow_ui.png](./evidence/airflow_ui.png)  
Screenshot of Airflow DAGs view showing pipelines loaded

![dag_run.png](./evidence/dag_run.png)  
Screenshot of DAG run completion

![log_parser_output.png](./evidence/log_parser_output.png)  
Screenshot of parsed log results




## 📎 Deliverables

- [`- docker-compose.yaml and requirements.txt`](./deliverables/- docker-compose.yaml and requirements.txt)

- [`- Python DAG scripts (dags/ folder)`](./deliverables/- Python DAG scripts (dags/ folder))

- [`- Log analyzer script (log_parser.py)`](./deliverables/- Log analyzer script (log_parser.py))

- [`- Raw container logs in /deliverables/logs/`](./deliverables/- Raw container logs in /deliverables/logs/)

- [`- README with project description and setup`](./deliverables/- README with project description and setup)




## 🛠️ Architecture
- Airflow DAG with parallel download and transform tasks
- CeleryExecutor for distributed task execution
- Python log analyzer for monitoring and reporting



## 🔍 Monitoring
- Airflow UI for DAG run monitoring
- Python log analyzer for automated error detection and reporting



## ♻️ Cleanup
- Remove temp data directories under /tmp/data
- Optionally drop DAG definition from Airflow once complete



*Generated automatically via Python + Jinja2 + SQL Server table `tblMiniProjectProgress` on 09-14-2025 23:37:22*