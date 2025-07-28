CI/CD & Helm Demo

This project demonstrates a full CI/CD pipeline using GitHub Actions and Helm charts, deploying to the Killercoda Kubernetes playground.

## Prerequisites
- GitHub repo with secrets:
  - `DOCKER_USERNAME` & `DOCKER_PASSWORD`
  - `KUBE_CONFIG_DATA` (base64 encoded kubeconfig)

## Workflow
- **CI** (`ci.yaml`): Builds backend & frontend images, scans with Trivy, pushes to Docker Hub.
- **CD** (`cd.yaml`): Installs Helm and deploys the `helm-chart/` to the playground.

## How to Run
1. Commit & push to `main` branch.
2. CI will run automatically.
3. Once CI succeeds, CD workflow deploys to your Killercoda cluster.
4. Access via Ingress host (`localhost` by default).

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

---

_All set! This gives you end-to-end CI/CD with security scans, image registry, Helm charts, and automated deploy on Killercoda._
