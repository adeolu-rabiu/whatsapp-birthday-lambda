FROM python:3.9-slim

WORKDIR /app

COPY . .

# add curl for the healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN pip install flask flask-cors python-dotenv requests

EXPOSE 8080

CMD ["python", "server.py"]

