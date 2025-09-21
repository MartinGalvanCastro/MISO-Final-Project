FROM grafana/grafana:10.1.0

# Set environment variables
ENV GF_SECURITY_ADMIN_PASSWORD=admin
ENV GF_USERS_ALLOW_SIGN_UP=false
ENV GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
ENV GF_SERVER_ROOT_URL=http://localhost:3000/grafana
ENV GF_SERVER_SERVE_FROM_SUB_PATH=true

# Copy provisioning configuration (excluding datasources)
COPY provisioning/dashboards /etc/grafana/provisioning/dashboards

# Copy only the production datasource configuration
COPY provisioning/datasources/prometheus-prod.yml /etc/grafana/provisioning/datasources/prometheus.yml

# Copy dashboards
COPY dashboards /var/lib/grafana/dashboards

# Expose Grafana port
EXPOSE 3000

# Use the default Grafana entrypoint
USER grafana