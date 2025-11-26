#!/bin/bash

echo "Initializing Airflow database..."
airflow db migrate

if [ -n "${AIRFLOW_ADMIN_USERNAME}" ] && [ -n "${AIRFLOW_ADMIN_PASSWORD}" ]; then
    echo "Creating admin user from environment variables..."
    airflow users create \
        --username "${AIRFLOW_ADMIN_USERNAME}" \
        --firstname "${AIRFLOW_ADMIN_FIRSTNAME:-Admin}" \
        --lastname "${AIRFLOW_ADMIN_LASTNAME:-User}" \
        --role "${AIRFLOW_ADMIN_ROLE:-Admin}" \
        --email "${AIRFLOW_ADMIN_EMAIL:-admin@example.com}" \
        --password "${AIRFLOW_ADMIN_PASSWORD}" || echo "User might already exist, continuing..."
else
    echo "Warning: AIRFLOW_ADMIN_USERNAME and AIRFLOW_ADMIN_PASSWORD not set. No admin user created."
fi

echo "Starting Airflow processes..."

airflow scheduler &

airflow dag-processor &

echo "Starting API Server..."
exec airflow api-server
