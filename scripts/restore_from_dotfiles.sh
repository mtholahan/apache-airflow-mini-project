#!/bin/bash

DOTFILES_AIRFLOW_DIR=~/code/dotfiles/airflow
AIRFLOW_DIR=~/airflow

echo "[*] Restoring Airflow config files from dotfiles backup..."

cp $DOTFILES_AIRFLOW_DIR/start-airflow.sh $AIRFLOW_DIR/
cp $DOTFILES_AIRFLOW_DIR/requirements.txt $AIRFLOW_DIR/
cp $DOTFILES_AIRFLOW_DIR/docker-compose.yaml $AIRFLOW_DIR/
cp $DOTFILES_AIRFLOW_DIR/Dockerfile.dev $AIRFLOW_DIR/
rsync -av --delete $DOTFILES_AIRFLOW_DIR/scripts/ $AIRFLOW_DIR/scripts/

echo "[✓] Restore complete."
