import os
from celery import Celery
from celery.schedules import crontab

broker_url = os.environ.get("CELERY_BROKER_URL", "redis://redis:6379/0")
backend_url = os.environ.get("CELERY_RESULT_BACKEND", "redis://redis:6379/1")

app = Celery("tasks", broker=broker_url, backend=backend_url)

app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

app.conf.beat_schedule = {
    "heartbeat-every-minute": {
        "task": "tasks.heartbeat",
        "schedule": crontab(minute="*"),
    },
}


@app.task
def add(x: int, y: int) -> int:
    return x + y


@app.task
def heartbeat() -> str:
    return "alive"
