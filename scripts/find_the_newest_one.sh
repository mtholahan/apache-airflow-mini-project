#!/bin/bash

echo "Comparing modification times for key files..."

FILES=("start-airflow.sh" "requirements.txt" "docker-compose.yaml" "Dockerfile.dev")

for FILE in "${FILES[@]}"; do
    echo -e "\n--- $FILE ---"
    stat ~/airflow/$FILE 2>/dev/null | grep "Modify" || echo "Not found: ~/airflow/$FILE"
    stat ~/code/dotfiles/airflow/$FILE 2>/dev/null | grep "Modify" || echo "Not found: dotfiles/$FILE"
    stat /mnt/c/Projects/apache-airflow-mini-project/$FILE 2>/dev/null | grep "Modify" || echo "Not found: Windows project/$FILE"
done
