#!/bin/bash

if [ -z "${FERNET_KEY}" ]; then
    export FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
fi

echo "=== Setting up DAGs ==="

if [ -n "${PROJECT_GIT_REPO}" ]; then
    echo "Cloning: ${PROJECT_GIT_REPO}"
    
    rm -rf /opt/airflow/project
    git clone ${PROJECT_GIT_REPO} /opt/airflow/project
    
    if [ $? -eq 0 ]; then
        echo "Project cloned successfully"
        
        export AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/project/workflows/dags
        
        export PYTHONPATH="/opt/airflow/project:$PYTHONPATH"
        
        echo "DAGs folder: $AIRFLOW__CORE__DAGS_FOLDER"
        echo "DAGs contents:"
        ls -la /opt/airflow/project/workflows/dags/
        
    else
        echo "Clone failed"
    fi
fi

echo "Starting Airflow..."
exec airflow standalone
