

from fastapi import FastAPI, Depends
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Counter, generate_latest
from nats.aio.client import Client as NATS
import os
import asyncio

app = FastAPI()


trace.set_tracer_provider(TracerProvider())
jaeger_exporter = JaegerExporter(agent_host_name="jaeger-agent", agent_port=6831)
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(jaeger_exporter))


PROCESS_COUNT = Counter('worker_process_total', 'Total processes')
nc = NATS()


@app.on_event("startup")
async def startup():
    await nc.connect(
        servers=[
            os.getenv('NATS_URL', 'nats://nats:4222')
        ]
    )
    asyncio.create_task(subscribe())


async def subscribe():
    async def message_handler(msg):
        print(f"Received: {msg.data.decode()}")
    await nc.subscribe("api.data.accessed", cb=message_handler)



@app.get("/health")
async def health():
    return {
        "status": "healthy"
    }


@app.get("/ready")
async def ready():
    return {
        "status": "ready"
    }


@app.get("/process")
async def process():
    PROCESS_COUNT.inc()
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("process_work"):
        await asyncio.sleep(0.5)
        await nc.publish("worker.processed", b"Work completed")
    
    return {
        "status": "completed"
    }


@app.get("/metrics")
async def metrics():
    return generate_latest()