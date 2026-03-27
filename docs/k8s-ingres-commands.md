## Step 1: Enable Ingress Controller in Minikube

### Enable ingress addon
minikube addons enable ingress

### Verify ingress controller running
kubectl get pods -n ingress-nginx

#### Expected:
#### NAME                                        READY   STATUS
#### ingress-nginx-controller-xxx                1/1     Running ✅

## Step 2: Create Ingress Resource
### Create a file named django-ingress.yml: 
kubectl apply -f django-ingress.yml

#### Check ingress
kubectl get ingress

#### Output:
#### NAME             CLASS   HOSTS          ADDRESS        PORTS
#### django-ingress   nginx   django.local   192.168.49.2   80

## Step 3: Update /etc/hosts
### Get Minikube IP
minikube ip
#### Output:
#### 192.168.49.2
#### Edit /etc/hosts and add:
#### 192.168.49.2 django.local
#### Also add: django.local to DJANGO_ALLOWED_HOSTS in django-configmap.yml and apply changes:
kubectl apply -f django-configmap.yml
kubectl rollout restart deployment django-deployment
curl http://django.local
#### Expected: You should see the Django welcome page. ✅

## Step 4: Create Multi-Service Ingress
### Create multi-ingress.yml with multiple paths for different services and apply it:
kubectl apply -f multi-ingress.yml
#### Test the paths:
curl http://myapp.local/        # Should route to Django ✅
curl http://myapp.local/api     # Should route to API ✅
curl http://myapp.local/admin   # Should route to Admin ✅

## Step 5: Create Multi-Domain Ingress
#### Create mulit-domain-ingress.yml with rules for different hostnames and apply it:
kubectl apply -f mulit-domain-ingress.yml
#### Test the hostnames:
curl http://django.local  # Should route to Django ✅
curl http://api.local     # Should route to API ✅

#### Note: Ensure you have entries for both django.local and api.local in your /etc/hosts file pointing to the Minikube IP.

## Step 6: Ingress with namespace
### Create an ingress resource in a specific namespace (e.g., production):
kubectl apply -f ingress-with-namespace.yml
#### Verify the ingress in the production namespace:
kubectl get ingress -n production
#### Output:
#### NAME             CLASS   HOSTS          ADDRESS        PORTS
#### django-ingress   nginx   myapp.com

## Step 7: Ingress with SSL
kubectl apply -f ingress-with-ssl.yml

### Create TLS Secret

#### Generate self-signed certificate (for testing)
openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout tls.key \
    -out tls.crt \
    -subj "/CN=myapp.com"

#### Create K8s secret from certificate
kubectl create secret tls myapp-tls-secret \
    --key tls.key \
    --cert tls.crt

## Step 8: Useful Ingress Annotations
metadata:
  annotations:
    # Rewrite URL path
    nginx.ingress.kubernetes.io/rewrite-target: /

    # Enable SSL redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"

    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "10"

    # Max request size
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"

    # Timeout
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"

    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"

## Nginx in Docker Compose vs Ingress in K8S:
```
Docker Compose                  Kubernetes
──────────────                  ──────────
nginx container                 Ingress Controller (nginx)
nginx.conf                      Ingress Resource (yaml rules)
proxy_pass http://web:8000      backend: django-service:8000
listen 80                       ports: 80
SSL in nginx.conf               TLS in Ingress spec
```

Same concept — different implementation! ✅

### Complete Setup Summary
```
minikube addons enable ingress
        │
        ▼
Ingress Controller running (nginx)
        │
        ▼
kubectl apply -f django-ingress.yml
        │
        ▼
Add to /etc/hosts:
192.168.49.2 django.local
        │
        ▼
curl http://django.local
        │
        ▼
Ingress Controller receives request
        │
        ▼
Matches rule: host=django.local path=/
        │
        ▼
Routes to django-service:8000
        │
        ▼
Django pod responds ✅
```

### Useful Ingress Commands

#### Get ingress
kubectl get ingress

#### Detailed ingress info
kubectl describe ingress django-ingress

#### Check ingress controller logs
kubectl logs -n ingress-nginx \
    deployment/ingress-nginx-controller

#### Delete ingress
kubectl delete ingress django-ingress




