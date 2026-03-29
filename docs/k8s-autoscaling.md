## Manual methdod 
kubectl scale deployment django-deployment --replicas=5 -n development

## Autoscaling methods
1. HPA - Horizontal Pod Autoscaling - Number of pods incremented based on usage
2. VPA - Vertical Pod Autoscaling - Pod resources increased or decreased based on usage

### Step 1: Enable Metrics Server
#### Enable on minikube
minikube addons enable metrics-server

#### Verify
kubectl get pods -n kube-system | grep metrics

#### Expected:
##### metrics-server-xxx   1/1   Running ✅

#### Test metrics working
kubectl top nodes
kubectl top pods

### Step 2: Create HPA
#### Method 1: Command Line
kubectl autoscale deployment django-deployment \
    --min=2 \
    --max=10 \
    --cpu-percent=70

#### Check HPA
kubectl get hpa

#### Method 2: HPA Yaml file
kubectl apply -f django-hpa.yml

#### Check HPA
kubectl get hpa

##### Output:
```
# NAME         REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS
# django-hpa   Deployment/django-deployment  15%/70%         2         10        2
#                                            current/target
```
## Step 3: Test HPA in Action
Generate load to trigger autoscaling:
```
# Terminal 1: Watch HPA
kubectl get hpa --watch

# Terminal 2: Watch pods
kubectl get pods --watch

# Terminal 3: Generate load
kubectl run load-generator \
    --image=busybox \
    --restart=Never \
    -- /bin/sh -c "while true; do wget -q -O- http://django-service:8000; done"
```

Watch Terminal 1 and 2:
```
# HPA detects high CPU
# TARGETS: 85%/70% → scaling up!

# New pods appear
# django-deployment-xxx   ContainerCreating
# django-deployment-xxx   Running
# django-deployment-xxx   Running    ← more pods! ✅

# Stop load generator
kubectl delete pod load-generator

# After 5 minutes HPA scales back down
# django-deployment-xxx   Terminating

```
## Useful Autoscaling commands
```
# Manual scaling
kubectl scale deployment django-deployment --replicas=5

# Create HPA
kubectl autoscale deployment django-deployment \
    --min=2 --max=10 --cpu-percent=70

# Get HPA
kubectl get hpa

# Describe HPA (detailed info)
kubectl describe hpa django-hpa

# Delete HPA
kubectl delete hpa django-hpa

# Check resource usage
kubectl top pods
kubectl top nodes

# Watch pods scaling in real time
kubectl get pods --watch

```

