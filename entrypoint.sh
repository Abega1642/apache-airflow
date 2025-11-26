#!/bin/bash

if [ -z "${FERNET_KEY}" ]; then
    export FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
fi

if [ -n "${PROJECT_GIT_REPO}" ]; then
    echo "Cloning project repository: ${PROJECT_GIT_REPO}"
    git clone ${PROJECT_GIT_REPO} /opt/airflow/project || echo "Clone failed or already exists"
    
    export PYTHONPATH="/opt/airflow/project:$PYTHONPATH"
    
    if [ -d "/opt/airflow/project/workflows/dags" ]; then
        ln -sf /opt/airflow/project/workflows/dags /opt/airflow/dags
        echo "DAGs linked successfully"
    else
        echo "No workflows/dags folder found in repo"
    fi
else
    echo "No PROJECT_GIT_REPO set, using default DAGs"
fi

echo "Starting Airflow standalone..."
exec airflow standalone
