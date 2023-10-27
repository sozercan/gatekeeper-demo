# Gatekeeper Demo

This demo shows how to use [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/) with both [Common Expression Language (CEL)](https://github.com/google/cel-spec) and [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) based policies side-by-side, with constraint violations published as messages to a subscriber using [Dapr](https://dapr.io/).

> [!WARNING]
> Gatekeeper CEL-based policies are a prototype-stage feature and is subject to change.

## Demo
[![asciicast](https://asciinema.org/a/617530.svg)](https://asciinema.org/a/617530)

## Getting started

### Pre-requisites
- [Docker](https://docs.docker.com/engine/install/)
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Bat](https://github.com/sharkdp/bat)

### Usage
`./demo.sh` to run the demo

## Architecture
![Architecture](./images/arch.png)
