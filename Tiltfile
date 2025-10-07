# Tiltfile
allow_k8s_contexts('kind-kind')

# Build and deploy services
docker_build('api-service', './services/api-service')
docker_build('worker-service', './services/worker-service')

k8s_yaml(['k8s/namespaces.yaml'])
k8s_yaml(listdir('k8s/infrastructures'))
k8s_yaml(listdir('k8s/services'))
k8s_yaml(listdir('k8s/ingress'))
k8s_yaml(listdir('k8s/linkerd'))

k8s_resource('api-service', port_forwards='8000:8000', resource_deps=['postgres', 'redis', 'nats'])
k8s_resource('worker-service', port_forwards='8001:8001', resource_deps=['nats'])
k8s_resource('grafana', port_forwards='3000:3000')
k8s_resource('prometheus', port_forwards='9090:9090')
k8s_resource('jaeger', port_forwards='16686:16686')
k8s_resource('keycloak', port_forwards='8080:8080')