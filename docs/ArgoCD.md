# ArgoCD implementation

## Installing ArgoCD on MiniKube cluster
1. kubectl create namespace argocd
2. kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/3. install.yaml
3. kubectl get pods -n argocd -w 
    ```
    NAME                                               READY   STATUS    RESTARTS        AGE
    argocd-application-controller-0                    1/1     Running   0               9m7s
    argocd-applicationset-controller-b7669f646-rgp4b   1/1     Running   2 (2m26s ago)   9m7s
    argocd-dex-server-569b757-mfpfk                    1/1     Running   0               9m7s
    argocd-notifications-controller-58ff87546-h9bg6    1/1     Running   0               9m7s
    argocd-redis-b9496d8bf-nkdz7                       1/1     Running   0               9m7s
    argocd-repo-server-75ffcfc9df-rfnfl                1/1     Running   0               9m7s
    argocd-server-76755b46f8-bghzg                     1/1     Running   0               9m7s
    ```

## Install ArgoCD CLI on system
1. curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
2. chmod +x argocd
3. sudo mv argocd /usr/local/bin/
    ```
    argocd: v3.4.3+1801122
    BuildDate: 2026-05-28T12:02:57Z
    GitCommit: 1801122b4391cad4961301f787006dc9a88c2dd3
    GitTreeState: clean
    GoVersion: go1.26.0
    Compiler: gc
    Platform: linux/amd64
    ```

## Expose ArgoCD
1. kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
2. kubectl get svc argocd-server -n argocd    
   ```
   service/argocd-server patched
   NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
   argocd-server   NodePort   10.105.130.82   <none>        80:32689/TCP,443:30746/TCP   24m
   ```

   ```
    Use following command if problem in login to ArgoCD

    kubectl port-forward svc/argocd-server -n argocd 8080:443 &
   ```

## Login to ArgoCD
1. Get password
    ```
    kubectl get secret argocd-initial-admin-secret \
    -n argocd \
    -o jsonpath="{.data.password}" | base64 --decode; echo
    ```
2. Lgin to ArgoCD
    ```
    argocd login localhost:<nodeport> --insecure --username admin \
    --password $(kubectl get secret argocd-initial-admin-secret \
    -n argocd -o jsonpath="{.data.password}" | base64 --decode)
    ```

## Create ArgoCD App
    ```
    argocd app create djstack \
    --repo https://github.com/subhash-devopslearner/djstack.git \
    --path helmcharts/djstack \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace dev \
    --helm-set django.image=subhashdevopslearner/djstack-web \
    --helm-set django.tag=1.0.0 \
    --sync-policy automated \
    --self-heal
    ```

## Check ArgoCD app status
    ```argocd app get djstack```

## Test the app
    ```curl http://djstack-app.local```

