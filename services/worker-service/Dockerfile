FROM python:3.11-slim
WORKDIR /app
RUN pip install fastapi uvicorn prometheus-client opentelemetry-api \
    opentelemetry-sdk opentelemetry-exporter-jaeger-thrift nats-py
COPY main.py .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]