FROM docker.elastic.co/beats/filebeat:8.12.2

USER root

# Copy Filebeat configuration
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

# Set proper permissions
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml && \
    chmod 0640 /usr/share/filebeat/filebeat.yml

USER filebeat
