# Dockerfile
FROM python:3.10-slim

WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the app
COPY . .

# Set environment variables (if any)
ENV PYTHONUNBUFFERED=1

# Entry point for testing — override in docker-compose
CMD ["python", "debug_birthday_scheduler.py"]

