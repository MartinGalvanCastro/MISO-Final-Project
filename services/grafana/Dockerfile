FROM grafana/grafana:10.1.0

# Set environment variables
ENV GF_SECURITY_ADMIN_PASSWORD=admin
ENV GF_USERS_ALLOW_SIGN_UP=false
ENV GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource

# Copy provisioning configuration
COPY provisioning /etc/grafana/provisioning

# Copy dashboards
COPY dashboards /var/lib/grafana/dashboards

# Expose Grafana port
EXPOSE 3000

# Use the default Grafana entrypoint
USER grafana