from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import os
import yfinance as yf
import pandas as pd

def get_target_date(context):
    date_str = context["dag_run"].conf.get("date") if context.get("dag_run") else None
    if date_str:
        return datetime.strptime(date_str, "%Y-%m-%d")
    else:
        return datetime.today() - timedelta(days=1)

def download_stock(ticker, **kwargs):
    date = get_target_date(kwargs)
    output_dir = f"/tmp/data/{date.strftime('%Y-%m-%d')}"
    os.makedirs(output_dir, exist_ok=True)

    df = yf.download(ticker, start=date, end=date + timedelta(days=1))
    if df.empty:
        raise ValueError(f"No data for {ticker} on {date}")
    df.to_csv(os.path.join(output_dir, f"{ticker}.csv"))
    print(f"✅ Saved {ticker}.csv")

def compute_average_close(**kwargs):
    date = get_target_date(kwargs)
    output_dir = f"/tmp/data/{date.strftime('%Y-%m-%d')}"

    aapl = pd.read_csv(os.path.join(output_dir, "AAPL.csv"))
    tsla = pd.read_csv(os.path.join(output_dir, "TSLA.csv"))
    
    aapl['ticker'] = 'AAPL'
    tsla['ticker'] = 'TSLA'

    combined = pd.concat([aapl, tsla])
    combined['Close'] = pd.to_numeric(combined['Close'], errors='coerce')
    avg = combined.groupby("ticker")["Close"].mean()

    print("\n📈 Average Close prices:")
    print(avg)

def verify_output(**kwargs):
    date = get_target_date(kwargs)
    output_dir = f"/tmp/data/{date.strftime('%Y-%m-%d')}"
    expected_files = ["AAPL.csv", "TSLA.csv"]
    
    for f in expected_files:
        fpath = os.path.join(output_dir, f)
        if not os.path.exists(fpath):
            raise FileNotFoundError(f"Missing file: {fpath}")
        if os.path.getsize(fpath) == 0:
            raise ValueError(f"File is empty: {fpath}")
        print(f"✅ File verified: {fpath}")

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

dag = DAG(
    'marketvol',
    default_args=default_args,
    description='Download and process stock prices',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
)

t1 = PythonOperator(
    task_id='download_aapl',
    python_callable=download_stock,
    op_kwargs={'ticker': 'AAPL'},
    provide_context=True,
    dag=dag,
)

t2 = PythonOperator(
    task_id='download_tsla',
    python_callable=download_stock,
    op_kwargs={'ticker': 'TSLA'},
    provide_context=True,
    dag=dag,
)

t3 = PythonOperator(
    task_id='compute_avg_close',
    python_callable=compute_average_close,
    provide_context=True,
    dag=dag,
)

t4 = PythonOperator(
    task_id='verify_output_files',
    python_callable=verify_output,
    provide_context=True,
    dag=dag,
)

[t1, t2] >> t4 >> t3
