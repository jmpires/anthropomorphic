# 📘 **ELK Stack using Self-Managed Kubernetes on AWS EC2**

### 📖 Article Link
Read the full article on Medium: [101 Deploying ELK Stack using Self-Managed Kubernetes on AWS EC2]()


### 📋 Code Structure

```
elkStackEc2/
├── kubernetes/
│   ├── app-deployment.yaml        # Multi-container app Pod with Filebeat sidecar and shared log volume
│   ├── es-deployment.yaml         # Single-node Elasticsearch deployment with health probes and ephemeral storage 
│   ├── es-svc.yaml                # NodePort service exposing Elasticsearch HTTP endpoint (port 9200)
│   ├── filebeat.yml               # Filebeat configuration for log collection and Logstash output
│   ├── kibana-deployment.yaml     # Kibana deployment (UI on port 5601) with health probes disabled
│   ├── kibana-svc.yaml            # NodePort service exposing Kibana UI on port 5601
│   ├── logstash-deployment.yml    # Logstash deployment with pipeline config from ConfigMap, listening on port 5044 for Filebeat
│   ├── logstash-svc.yml           # NodePort service exposing Logstash input endpoint (port 5044) for Filebeat
│   └── logstash.conf              # Logstash pipeline: ingest Filebeat logs, parse JSON, enrich with GeoIP, output to Elasticsearch
├── tools/                         # A set of comprehensive tools for automation and utility functions
└── README.md                      # Project overview, prerequisites, and quick start instructions~
```
