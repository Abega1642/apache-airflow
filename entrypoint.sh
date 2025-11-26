#!/bin/bash

if [ -z "${FERNET_KEY}" ]; then
    export FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
fi

echo "=== Setting up project as DAGs directory ==="

if [ -n "${PROJECT_GIT_REPO}" ]; then
    echo "Cloning project: ${PROJECT_GIT_REPO}"
    
    rm -rf /opt/airflow/project
    git clone ${PROJECT_GIT_REPO} /opt/airflow/project
    
    if [ $? -eq 0 ]; then
        echo "Project cloned successfully"
        
        export AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/project
        
        export PYTHONPATH="/opt/airflow/project:$PYTHONPATH"
        
        echo "Project structure:"
        ls -la /opt/airflow/project/
        echo "Python path: $PYTHONPATH"
        echo "DAGs folder: $AIRFLOW__CORE__DAGS_FOLDER"
        
        echo "Looking for Python files in project:"
        find /opt/airflow/project -name "*.py" | head -10
    else
        echo "Git clone failed"
    fi
else
    echo "No PROJECT_GIT_REPO set"
fi

echo "Starting Airflow (scanning entire project for DAGs)..."
exec airflow standalone
