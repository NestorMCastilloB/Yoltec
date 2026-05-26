FROM python:3.12-slim

WORKDIR /app

# cache bust: 2026-05-25
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Modelo pre-entrenado (sintético 53k + CSV real 34k) — ya no se entrena en build
COPY app.py feature_names.json model.pkl label_encoder.pkl ./

EXPOSE 5000

CMD ["python", "app.py"]
