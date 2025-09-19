#!/bin/bash

# 🧠 Sync from ~/airflow (dev) to:
#  1. ~/code/dotfiles/airflow
#  2. C:\Projects\apache-airflow-mini-project (via /mnt/c mount)

set -e  # 🔥 Exit on first error

# === Paths ===
AIRFLOW_DIR=~/airflow
DOTFILES_DIR=~/code/dotfiles
DOTFILES_AIRFLOW_DIR=$DOTFILES_DIR/airflow
DOTFILES_SCRIPTS_DIR=$DOTFILES_DIR/scripts
MINIPROJECT_DIR="/mnt/c/Projects/apache-airflow-mini-project"

# === 1️⃣ Sync to dotfiles (excluding scripts) ===
echo "[*] Syncing essentials into dotfiles..."

mkdir -p "$DOTFILES_AIRFLOW_DIR"/{dags,logs}

cp "$AIRFLOW_DIR/start-airflow.sh" "$DOTFILES_AIRFLOW_DIR/"
cp "$AIRFLOW_DIR/requirements.txt" "$DOTFILES_AIRFLOW_DIR/"
cp "$AIRFLOW_DIR/docker-compose.yaml" "$DOTFILES_AIRFLOW_DIR/"
cp "$AIRFLOW_DIR/Dockerfile.dev" "$DOTFILES_AIRFLOW_DIR/"

rsync -av --delete \
  --exclude '__pycache__' \
  --exclude 'dag_processor_manager/' \
  --exclude 'scheduler/' \
  "$AIRFLOW_DIR/dags/" "$DOTFILES_AIRFLOW_DIR/dags/"

rsync -av --delete \
  --exclude '__pycache__' \
  --exclude 'dag_processor_manager/' \
  --exclude 'scheduler/' \
  "$AIRFLOW_DIR/logs/" "$DOTFILES_AIRFLOW_DIR/logs/"

echo "[✓] Dotfiles sync complete."

# === 2️⃣ Sync into Windows project repo ===
echo "[*] Syncing to Windows mini-project repo..."

mkdir -p "$MINIPROJECT_DIR"/{dags,scripts,logs}

cp "$AIRFLOW_DIR/start-airflow.sh" "$MINIPROJECT_DIR/"
cp "$AIRFLOW_DIR/requirements.txt" "$MINIPROJECT_DIR/"
cp "$AIRFLOW_DIR/docker-compose.yaml" "$MINIPROJECT_DIR/"
cp "$AIRFLOW_DIR/Dockerfile.dev" "$MINIPROJECT_DIR/"

rsync -av --delete "$AIRFLOW_DIR/dags/" "$MINIPROJECT_DIR/dags/"

rsync -av --delete \
  --exclude '__pycache__' \
  "$DOTFILES_SCRIPTS_DIR/" "$MINIPROJECT_DIR/scripts/"

# ✅ Copy latest combined log into logs/ (if found)
COMBINED_LOG=$(find "$AIRFLOW_DIR" -maxdepth 1 -name "marketvol_combined_log_*.txt" | sort | tail -n 1)
if [[ -n "$COMBINED_LOG" ]]; then
    echo "[*] Found latest combined log: $COMBINED_LOG"
    cp "$COMBINED_LOG" "$MINIPROJECT_DIR/logs/"
else
    echo "[!] No combined log file found. Skipping..."
fi

echo "[✓] Windows sync complete."
