FROM python:3.11-slim

WORKDIR /app

# cache bust: 2026-04-08b
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py train_model_light.py enfermedades_config.json ./

# Entrenar modelo ligero durante el build
RUN python train_model_light.py

EXPOSE 8080

CMD ["python", "app.py"]
