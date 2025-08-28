# type: ignore
import sys
import os
from airflow.operators.python import PythonOperator
from airflow import DAG
from datetime import datetime

# Add absolute path to the `scripts` folder
scripts_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scripts'))
if scripts_path not in sys.path:
    sys.path.insert(0, scripts_path)

from log_analyzer import analyze_file

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2025, 8, 27),
}

with DAG(
    'log_analyzer',
    schedule_interval=None,
    default_args=default_args,
    catchup=False,
    tags=['Airflow Mini Project'],
    ) as dag:

    # Analyze AAPL logs only
    t1 = PythonOperator(
        task_id='analyze_download_aapl_logs',
        python_callable=analyze_file,
        op_args=['/opt/airflow/logs/dag_id=marketvol', 'download_aapl'],
        dag=dag
    )

    # Analyze TSLA logs only
    t2 = PythonOperator(
        task_id='analyze_download_tsla_logs',
        python_callable=analyze_file,
        op_args=['/opt/airflow/logs/dag_id=marketvol', 'download_tsla'],
        dag=dag
    )

t1 >> t2