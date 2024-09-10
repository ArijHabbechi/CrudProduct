./update-mysql-secret.sh

# Apply the MySQL secret
kubectl apply -f mysql-secret.yml

# Apply the MySQL deployment and service
kubectl apply -f mysql-configmap.yml
kubectl apply -f mysql-deployment.yml

# Apply the Spring Boot deployment and service
kubectl apply -f springapp-deployment.yml
kubectl apply -f springapp-config.yml

# Optionally clean up the generated secret file
#rm -f mysql-secret.yml


# Retrieve the NodePort for the Spring app service
NODE_PORT=$(kubectl get svc springapp -o=jsonpath='{.spec.ports[0].nodePort}')

echo "Deployment completed."
