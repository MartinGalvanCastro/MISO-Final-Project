FROM prom/prometheus:v2.45.0

# Copy the prometheus configuration
COPY prometheus.yml /etc/prometheus/prometheus.yml

# Expose the default Prometheus port
EXPOSE 9090

# Use the default Prometheus entrypoint
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
     "--storage.tsdb.path=/prometheus", \
     "--web.console.libraries=/etc/prometheus/console_libraries", \
     "--web.console.templates=/etc/prometheus/consoles", \
     "--storage.tsdb.retention.time=15d", \
     "--web.enable-lifecycle"]