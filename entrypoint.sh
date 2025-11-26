#!/bin/bash

if [ -z "${FERNET_KEY}" ]; then
    export FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
fi

if [ -n "${PROJECT_GIT_REPO}" ]; then
    echo "Cloning entire project repository..."
    git clone ${PROJECT_GIT_REPO} /opt/airflow/project
    
    export PYTHONPATH="/opt/airflow/project:$PYTHONPATH"
    
    ln -sf /opt/airflow/project/workflows/dags /opt/airflow/dags
    
    echo "Project cloned successfully!"
    echo "Python path includes: /opt/airflow/project"
    echo "DAGs linked from: /opt/airflow/project/workflows/dags"
    echo "All imports available: src/, config/, data/, workflows/, resources/"
fi

exec airflow standalone
