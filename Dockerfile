FROM apache/airflow:slim-3.1.3-python3.13

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        build-essential \
        curl \
        libffi-dev \
        libssl-dev \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

USER airflow

ENV AIRFLOW_HOME=/opt/airflow
ENV AIRFLOW__CORE__EXECUTOR=LocalExecutor
ENV AIRFLOW__CORE__LOAD_EXAMPLES=false
ENV AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=true
ENV AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY}
ENV AIRFLOW__API__AUTH_BACKENDS=airflow.api.auth.backend.basic_auth
ENV AIRFLOW__WEBSERVER__RBAC=true

RUN mkdir -p ${AIRFLOW_HOME}/dags \
    ${AIRFLOW_HOME}/logs \
    ${AIRFLOW_HOME}/plugins \
    ${AIRFLOW_HOME}/config

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
