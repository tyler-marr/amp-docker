FROM grafana/grafana:6.2.5

COPY grafana.ini /etc/grafana/grafana.ini
COPY datasources.yml /etc/grafana/provisioning/datasources/datasources.yaml
COPY dashboards.yml /etc/grafana/provisioning/dashboards/dashboard.yaml
COPY my-fancy-dashboard.json /etc/grafana/provisioning/dashboards/my-fancy-dashboard.json