FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY frontend/templates ./frontend/templates/
COPY frontend/static ./frontend/static/

COPY backend/app.py backend/main.py ./

RUN mkdir -p database/data

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--reload", "app:app"]