#!/bin/bash

. third_party/demo-magic/demo-magic.sh

clear
DEMO_PROMPT="${GREEN}➜  ${COLOR_RESET}"

# setup begins
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
pei "kubectl apply -f manifests/dapr-component-subscriber.yaml"
pei "docker build "https://github.com/open-policy-agent/gatekeeper.git#:test/pubsub/fake-subscriber" -t fake-subscriber:latest"
pei "kind load docker-image --name gk-demo fake-subscriber:latest"
pei "kubectl apply -f manifests/subscriber-deployment.yaml"
pei "kubectl rollout status deployment -n fake-subscriber sub"

echo "setting up Gatekeeper"
pei "kubectl create namespace gatekeeper-system"
pei "kubectl get secret redis --namespace=default -o yaml | sed 's/namespace: .*/namespace: gatekeeper-system/' | kubectl apply -f -"
pei "kubectl apply -f manifests/dapr-component-gatekeeper.yaml"
pei "kubectl apply -f manifests/gatekeeper-3.14-cel.yaml"
pei "kubectl rollout status deployment -n gatekeeper-system gatekeeper-controller-manager"
pei "kubectl rollout status deployment -n gatekeeper-system gatekeeper-audit"
pei "kubectl apply -f manifests/gatekeeper-configmap-pubsub.yaml"
# setup is complete

# demo starts here
echo "Let's get started by looking into components deployed into the cluster"
pe "kubectl get pods --all-namespaces"
wait

clear

echo "First, we are going to deploy a Common Expression Language (CEL) based policy"
wait
bat policies/constrainttemplate-cel.yaml --paging never
wait
pe "kubectl apply -f policies/constrainttemplate-cel.yaml"
bat policies/constraint-cel.yaml --paging never
wait
pe "kubectl apply -f policies/constraint-cel.yaml"

clear

echo "Next, we are going to deploy a Rego-based policy side-by-side with the CEL-based policy"
wait
bat policies/constrainttemplate-rego.yaml --paging never
wait
pe "kubectl apply -f policies/constrainttemplate-rego.yaml"
bat policies/constraint-rego.yaml --paging never
wait
pe "kubectl apply -f policies/constraint-rego.yaml"

clear

echo "Let's look into violations coming from the CEL-based policy in constraint resource"
wait
pe "kubectl get k8srequiredlabels.constraints.gatekeeper.sh all-must-have-owner -o yaml"
wait

clear

echo "Finally, these violations can be consumed by a subscriber via pubsub"
wait
pe "kubectl logs -l app=sub -c go-sub -n fake-subscriber -f"

echo "More information can be found at https://open-policy-agent.github.io/gatekeeper/website/"

# echo "cleanup"
# kubectl delete constrainttemplate --all
# kind delete cluster --name gk-demo
