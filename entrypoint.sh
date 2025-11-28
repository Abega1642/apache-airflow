#!/bin/bash
set -e

echo "=== Airflow 3.x Initialization ==="
echo "Current user: $(whoami)"
echo "Working directory: $(pwd)"


if [ -z "${FERNET_KEY}" ]; then
    export FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
    echo "Generated Fernet key"
fi


export AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags


if [ -n "${PROJECT_GIT_REPO}" ]; then
    echo "=== Cloning project repository ==="
    echo "Repository: ${PROJECT_GIT_REPO}"
    
    rm -rf /opt/airflow/project
    
    if git clone ${PROJECT_GIT_REPO} /opt/airflow/project; then
        echo "Project cloned successfully"
        

        if [ -d "/opt/airflow/project/workflows/dags" ]; then
            export AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/project/workflows/dags
            echo "DAGs folder found: $AIRFLOW__CORE__DAGS_FOLDER"
        else
            echo "DAGs folder not found at /opt/airflow/project/workflows/dags"
            echo "Available directories:"
            find /opt/airflow/project -type d -name "*dag*" 2>/dev/null || echo "No dag folders found"
        fi
        

        export PYTHONPATH="/opt/airflow/project:$PYTHONPATH"
        

        if [ -d "$AIRFLOW__CORE__DAGS_FOLDER" ]; then
            echo "DAGs in folder:"
            ls -lah $AIRFLOW__CORE__DAGS_FOLDER/ || echo "Cannot list DAGs"
        fi
    else
        echo "Failed to clone repository"
        echo "Using default DAGs folder: /opt/airflow/dags"
    fi
else
    echo "No PROJECT_GIT_REPO provided, using default DAGs folder"
fi

echo "=== Initializing Airflow database ==="
airflow db migrate || {
    echo "Database migration failed!"
    exit 1
}


if [ -n "${AIRFLOW_ADMIN_USERNAME}" ] && [ -n "${AIRFLOW_ADMIN_PASSWORD}" ]; then
    echo "=== Creating admin user ==="
    airflow users create \
        --username "${AIRFLOW_ADMIN_USERNAME}" \
        --firstname "${AIRFLOW_ADMIN_FIRSTNAME:-Admin}" \
        --lastname "${AIRFLOW_ADMIN_LASTNAME:-User}" \
        --role Admin \
        --email "${AIRFLOW_ADMIN_EMAIL:-admin@example.com}" \
        --password "${AIRFLOW_ADMIN_PASSWORD}" 2>&1 | grep -v "already exists" || echo "✓ Admin user ready"
else
    echo "WARNING: AIRFLOW_ADMIN_USERNAME and AIRFLOW_ADMIN_PASSWORD not set!"
    echo "Skipping user creation - you'll need to create a user manually"
fi

echo "=== Starting Airflow API Server (UI + REST API) ==="
airflow api-server --port 8080 &
API_SERVER_PID=$!


echo "Waiting for API server to start..."
sleep 15


echo "=== Starting Airflow scheduler ==="
airflow scheduler &
SCHEDULER_PID=$!


wait_for_processes() {
    while true; do
        if ! kill -0 $API_SERVER_PID 2>/dev/null; then
            echo "API Server died, exiting..."
            exit 1
        fi
        if ! kill -0 $SCHEDULER_PID 2>/dev/null; then
            echo "Scheduler died, exiting..."
            exit 1
        fi
        sleep 5
    done
}

trap "kill $API_SERVER_PID $SCHEDULER_PID 2>/dev/null; exit 0" SIGTERM SIGINT

echo "=== Airflow 3.x is running ==="
echo "UI & API: http://localhost:8080"
echo "Username: admin | Password: admin"

wait_for_processes
