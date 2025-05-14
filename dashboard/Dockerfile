FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install flask flask-cors python-dotenv

EXPOSE 8080

CMD ["python", "server.py"]

