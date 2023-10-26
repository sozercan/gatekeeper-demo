#!/bin/bash

. third_party/demo-magic/demo-magic.sh

clear

echo "setting up kind cluster"
pei "kind create cluster --name gk-demo --wait 5m"
pei "kubectl version"

echo "deploying dapr runtime"
pei "helm upgrade --install dapr dapr/dapr --version=1.12.0 --namespace dapr-system --create-namespace --wait \
    --set dapr_sidecar_injector.sidecarDropALLCapabilities=true \
    --set global.actors.enabled=false"

echo "deploying redis as pubsub broker"
pei "helm upgrade --install redis bitnami/redis --namespace default --set image.tag=7.0-debian-11 --wait"

echo "setting up subscriber"
pei "kubectl create ns fake-subscriber"
pei "kubectl get secret redis --namespace=default -o yaml | sed 's/namespace: .*/namespace: fake-subscriber/' | kubectl apply -f -"
pei "kubectl apply -f dapr-component-subscriber.yaml"
pei "docker build "https://github.com/open-policy-agent/gatekeeper.git#:test/pubsub/fake-subscriber" -t fake-subscriber:latest"
pei "kind load docker-image --name gk-demo fake-subscriber:latest"
pei "kubectl apply -f subscriber-deployment.yaml"
pei "kubectl rollout status deployment -n fake-subscriber sub"

echo "setting up Gatekeeper"
pei "kubectl create namespace gatekeeper-system"
pei "kubectl get secret redis --namespace=default -o yaml | sed 's/namespace: .*/namespace: gatekeeper-system/' | kubectl apply -f -"
pei "kubectl apply -f dapr-component-gatekeeper.yaml"
pei "kubectl apply -f gatekeeper-3.14-cel.yaml"
pei "kubectl rollout status deployment -n gatekeeper-system gatekeeper-controller-manager"
pei "kubectl rollout status deployment -n gatekeeper-system gatekeeper-audit"
pei "kubectl apply -f gatekeeper-configmap-pubsub.yaml"

echo "deploying cel and rego policies"
pei "kubectl apply -f policies/constrainttemplate-cel.yaml"
pei "kubectl apply -f policies/constraint-cel.yaml"

pei "kubectl apply -f policies/constrainttemplate-rego.yaml"
pei "kubectl apply -f policies/constraint-rego.yaml"

kubectl logs -l app=sub -c go-sub -n fake-subscriber -f

# echo "cleanup cluster"
# p "kind delete cluster --name gk-demo"

echo "More information can be found at https://open-policy-agent.github.io/gatekeeper/website/"
