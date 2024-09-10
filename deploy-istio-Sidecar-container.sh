#!/bin/bash

# Apply the MySQL secret in the istio-system namespace
kubectl apply -f mysql-secret.yml -n istio-system

# Apply the MySQL ConfigMap in the istio-system namespace
kubectl apply -f mysql-configmap.yml -n istio-system

# Apply the MySQL deployment with Istio sidecar injection in the istio-system namespace
kubectl apply -f <(istioctl kube-inject -f mysql-deployment.yml) -n istio-system

# Apply the Spring Boot ConfigMap in the istio-system namespace
kubectl apply -f springapp-config.yml -n istio-system

# Apply the Spring Boot deployment with Istio sidecar injection in the istio-system namespace
kubectl apply -f <(istioctl kube-inject -f springapp-deployment.yml) -n istio-system




