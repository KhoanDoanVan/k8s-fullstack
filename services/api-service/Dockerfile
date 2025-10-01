FROM python:3.11-slim
WORKDIR /app
RUN pip install fastapi uvicorn prometheus-client opentelemetry-api \
    opentelemetry-sdk opentelemetry-instrumentation-fastapi \
    opentelemetry-exporter-jaeger-thrift pyjwt redis psycopg2-binary \
    nats-py httpx
COPY main.py .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]