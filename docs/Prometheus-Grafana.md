# Prometheus and Grafana implementation

## Installation of Prometheus and Grafana
1. `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
2. `helm repo update`
3. `helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace`
4. `kubectl --namespace monitoring get pods -l "release=prometheus"`
5. `export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=prometheus" -oname)`
6. `get secret prometheus-grafana -o jsonpath="{.data.admin-user}" | base64 -d; echo`
7. `get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo`
8. `kubectl --namespace monitoring port-forward "$POD_NAME" 3000`

## Login to Grafana
`Access http://localhost:3000 and with username as admin and password from step-7`

## Install django_prometheus app in Django
1. Add django-prometheus in requirements.txt
2. Add settings for django-prometheus app in Django
3. Check settings.py - apps, middleware and urls.py for clarity

## Check label in Djagno service
```
metadata:
  name: django-service
  labels:
    app: django
```
This label should match with selector in service monitor

## Create Service Monitor 
Service monitor will watch django-service for following endpoint every 15 seconds
```
spec:
  selector:
    matchLabels:
      app: django
  endpoints:
  - port: web
    path: /django-prometheus/metrics
    interval: 15s
```
## Test Prometheus scraping app data
In Grafana UI, go to Explore → Prometheus → Code mode, and run:
`python_info{namespace="dev"}`

## Run real load in cluster
```
kubectl run curl-pod --image=curlimages/curl --rm -it -n dev -- sh

for i in $(seq 1 50); do curl django-service/django-prometheus/metrics > /dev/null; curl djstack-app.local 2>/dev/null > /dev/null; done
```

## Build dashboard in Grafana
1. Dashboards → New → New Dashboard
2. Panel 1 — Request Rate: `rate(django_http_requests_total_by_method_total[1m])`
3. Panel 2 — Response Time: `rate(django_http_requests_latency_seconds_by_view_method_sum[1m])`
4. Panel 3 — Total Pods: `count(kube_pod_status_phase{phase="Running", namespace="dev"})`
5. Save as "Django App"





