
FROM docker.elastic.co/beats/filebeat:8.12.2

USER root

# Add custom Filebeat configuration
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

RUN chown root:filebeat /usr/share/filebeat/filebeat.yml && \
    chmod 644 /usr/share/filebeat/filebeat.yml

USER filebeat

ENTRYPOINT ["/usr/share/filebeat/filebeat", "-e"]
