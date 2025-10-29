#!/bin/bash

echo "🔧 Complete Cron Path Fix"
echo "=========================="
echo ""

cd /opt/whatsapp-birthday-lambda

# 1. Fix LOG_DIR in Python script
echo "1️⃣ Fixing LOG_DIR in Python script..."
sed -i 's|LOG_DIR = "/opt/whatsapp-birthday-lambda/logs"|LOG_DIR = "/app/logs"|g' app/whatsapp/whatsapp_birthday_service.py
echo "✅ LOG_DIR updated to /app/logs"
echo ""

# 2. Update Dockerfile.cron with correct paths
echo "2️⃣ Updating Dockerfile.cron..."
cat > Dockerfile.cron << 'DOCKERFILE'
FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y cron curl && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    boto3==1.28.53 \
    python-dateutil \
    pytz \
    requests==2.31.0 \
    python-dotenv

COPY ./app ./app
RUN mkdir -p /app/logs

ENV WPPCONNECT_URL=http://wppconnect-bot:3005
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Correct path: /app/whatsapp/ (not /app/app/whatsapp/)
RUN echo "PATH=/usr/local/bin:/usr/bin:/bin" > /etc/cron.d/birthday-cron && \
    echo "0 8 * * * root cd /app && /usr/local/bin/python3 /app/whatsapp/whatsapp_birthday_service.py >> /app/logs/cron.log 2>&1" >> /etc/cron.d/birthday-cron

RUN chmod 0644 /etc/cron.d/birthday-cron
RUN crontab /etc/cron.d/birthday-cron
RUN touch /app/logs/cron.log

CMD ["cron", "-f"]
DOCKERFILE

echo "✅ Dockerfile.cron updated"
echo ""

# 3. Rebuild cron container
echo "3️⃣ Rebuilding cron container..."
docker-compose build cron
docker-compose restart cron

echo ""
echo "Waiting for container to start..."
sleep 5

# 4. Verify setup
echo ""
echo "4️⃣ Verifying setup..."
echo ""
echo "Crontab entry:"
docker exec whatsapp-birthday-lambda_cron crontab -l

echo ""
echo "File exists in container:"
docker exec whatsapp-birthday-lambda_cron ls -la /app/whatsapp/whatsapp_birthday_service.py

# 5. Test execution
echo ""
echo "5️⃣ Testing script execution..."
docker exec whatsapp-birthday-lambda_cron /usr/local/bin/python3 /app/whatsapp/whatsapp_birthday_service.py

# 6. Check results
echo ""
echo "6️⃣ Checking logs..."
docker exec whatsapp-birthday-lambda_cron cat /app/logs/cron.log | tail -30

echo ""
echo "=========================="
echo "✅ Fix Complete!"
echo ""
echo "Summary of changes:"
echo "  • Fixed LOG_DIR: /opt/whatsapp-birthday-lambda/logs → /app/logs"
echo "  • Fixed crontab path: /app/app/whatsapp/... → /app/whatsapp/..."
echo "  • Added PATH to crontab"
echo "  • Used full Python path: /usr/local/bin/python3"
echo ""
echo "Cron will run daily at 8:00 AM"
echo ""
echo "Manual test command:"
echo "  docker exec whatsapp-birthday-lambda_cron /usr/local/bin/python3 /app/whatsapp/whatsapp_birthday_service.py"
