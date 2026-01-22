# 📘 **Implementing Production-Grade Deployment Strategies on Kubernetes (EC2)**

### 📖 Article Link
Read the full article on Medium: [Implementing Production-Grade Deployment Strategies on Kubernetes (EC2)](...)


### 📋 Code Structure

```
3deployStrategiesEc2/
├── docs/                          # Architecture notes, diagrams, and operational guidance
├── yaml/                          
│   ├── blue-deployment.yaml       # Blue (stable) deployment for Blue/Green strategy
│   ├── blue-green-service.yaml    # Service routing to active version via label selector
│   ├── canary-ingress.yaml        # Ingress with weighted traffic split for Canary (e.g., 90/10)
│   ├── canary-v1.yaml             # Stable version (v1) in Canary deployment
│   ├── canary-v2.yaml             # Canary version (v2) receiving test traffic
│   ├── green-deployment.yaml      # Green (candidate) deployment for Blue/Green strategy
│   ├── ingress.yaml               # Base NGINX Ingress Controller setup
│   ├── rollingupdate-v1.yaml      # Initial app version (v1) for Rolling Update
│   ├── rollingupdate-v2.yaml      # Updated app version (v2) triggering rolling replacement
│   └── rollingupdate-v3.yaml      # Further update (v3) demonstrating multi-stage rollout
└── README.md                      # Project overview, prerequisites, and quick start instructions
```
