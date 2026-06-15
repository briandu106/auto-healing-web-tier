# Self-Healing, Auto-Provisioning Web Tier
An idempotent, single-command deployment executing a highly available, containerized web cluster on AWS with downtime tolerance for single node failures.

## Why did I choose AWS, not Azure?
AWS is selected for this footprint because of the operational efficiency of its **Application Load Balancer (ALB)** combined with **Auto Scaling Groups (ASG)**. 
1. **Finer Health Probe Granularity:** AWS allows target groups to cycle health checks as low as 5-10 second intervals, triggering instantaneous instance terminations.
2. **Native `ELB` Health Check Type:** Unlike Azure VMSS which heavily relies on separate application gateway probes or custom script extensions to report health states, AWS allows the ASG to directly monitor the ALB target health state, optimizing the self-healing feedback loop.

## Architecture & Self-Healing Logic
* **N+1 Fault Tolerance:** The design forces a minimum size of 2 instances mapped across unique Availability Zones. If instance `A` drops, instance `B` handles 100% of the traffic without downtime.
* **Auto-Healing Loop:** The ASG evaluates the EC2 state via `ELB` target group health status. If a container drops or a VM is terminated manually, the target becomes unhealthy, the ASG terminates the stale node, and provisions a brand new instance instantly via the `user_data.sh` immutable definition.

## Architecture Diagram
                      [ Public Internet ]
                              │
                              ▼
                    [ Internet Gateway ]
                              │
                              ▼
                      [ Public Route Table ]
                              │
           ┌──────────────────┴──────────────────┐
           ▼                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│ ap-southeast-4 (Melbourne Region) - VPC                                │
│                                                                        │
│  ┌──────────────────────────────┐    ┌──────────────────────────────┐  │
│  │ Availability Zone A          │    │ Availability Zone B          │  │
│  │                              │    │                              │  │
│  │ ┌──────────────────────────┐ │    │ ┌──────────────────────────┐ │  │
│  │ │ Public Subnet 1          │ │    │ │ Public Subnet 2          │ │  │
│  │ │ (10.0.1.0/24)            │ │    │ │ (10.0.2.0/24)            │ │  │
│  │ │                          │ │    │ │                          │ │  │
│  │ │  ┌────────────────────┐  │ │    │ │  ┌────────────────────┐  │ │  │
│  │ │  │   Application      │◀─┼─┼────┼─┼─▶│   Application      │  │ │  │
│  │ │  │   Load Balancer    │  │ │    │ │  │   Load Balancer    │  │ │  │
│  │ │  │   (Node 1)         │  │ │    │ │  │   (Node 2)         │  │ │  │
│  │ │  └─────────┬──────────┘  │ │    │ │  └─────────┬──────────┘  │ │  │
│  │ │            │ (Port 80)   │ │    │ │            │ (Port 80)   │ │  │
│  │ └────────────┼─────────────┘ │    │ └────────────┼─────────────┘  │
│  └──────────────┼───────────────┘    └──────────────┼────────────────┘
│                 │                                   │                   
│                 └─────────────────┬─────────────────┘                   
│                                   ▼                                     
│                     [ ALB Target Group: Port 80 ]                       
│                                   │                                     
│     ┌─────────────────────────────┴─────────────────────────────┐       
│     ▼                                                           ▼       
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Auto Scaling Group (Desired: 2 / Max: 4)                        │   │
│  │                                                                 │   │
│  │  ┌──────────────────────────────┐    ┌─────────────────────────┐│   │
│  │  │ EC2 Web Instance (Node 1)    │    │ EC2 Web Instance (Node 2││   │
│  │  │                              │    │                         ││   │
│  │  │  ┌────────────────────────┐  │    │  ┌────────────────────┐ ││   │
│  │  │  │ Host Network Stack     │  │    │  │ Host Network Stack │ ││   │
│  │  │  │                        │  │    │  │                    │ ││   │
│  │  │  │ ┌────────────────────┐ │  │    │  │ ┌────────────────┐ ││   │
│  │  │  │ │ NGINX Container    │ │  │    │  │ │ NGINX Container│ ││   │
│  │  │  │ │ (Port 80:80)       │ │  │    │  │ │ (Port 80:80)   │ ││   │
│  │  │  │ └────────────────────┘ │  │    │  │ └────────────────┘ ││   │
│  │  │  └────────────────────────┘  │    │  └────────────────────┘ ││   │
│  │  └──────────────────────────────┘    └─────────────────────────┘│   │
│  └─────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ (Outbound image pull over HTTPS)
                                    │
                         [ GitHub Container Registry ]
                         (ghcr.io/briandu106/nginx-autoscale)

## Build and push contaaner image to GHCR
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/briandu106/nginx-autoscale:latest \
  --push .docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/briandu106/nginx-autoscale:latest \
  --push .

## Estimated Monthly Cost (AUD)
Optimized strictly under the **AUD $20 / month** target limit using AWS Free Tier elegibility/low-cost components where applicable:

| Component | AWS Resource Type | Configuration | Estimated Cost (USD) | Estimated Cost (AUD) |
| :--- | :--- | :--- | :--- | :--- |
| **Compute** | EC2 Instances | 2x `t4g.nano` (using free tier) | ~$9.37 | ~$14.20 |
| **Storage** | EBS Volumes | 2x 8GB gp3 volumes | ~$1.28 | ~$1.95 |
| **Network** | Application Load Balancer | 1 ALB (Low traffic LCU rules) | ~$6.00 (partial region scale) | ~$9.00 |
| **Data Transfer**| Internet Egress | < 1 GB | $0.00 | $0.00 |
| **Total** | | | **~$16.65** | **~$25.15** |

*(Note: It exceeds the total monthly cost of AUD 20 because the cost that drives the most is the requirement to have at least 2 instances behind a load balancer. It's a trade-off between cost and stability.*

## How to Execute

### From local machine

#### Prerequisites
* Set up AWS Credentials locally (`aws configure` or Export variables).
* Install Terraform v1.5+.

#### Deployment Steps
* Clone the code
* Export sample AWS credentials
```bash
export AWS_ACCESS_KEY_ID="sample-key"
export AWS_SECRET_ACCESS_KEY="sample-secret"
* Run a live test
```bash
terraform init   
terraform plan   # This will print out the list of all AWS resources that are to be created

### From GitHub Actions
* Create repositoy variables:
AWS_ACCESS_KEY_ID="sample_key"
AWS_SECRET_ACCESS_KEY="sample-secret"
AWS_REGION=""ap-southeast-4"
* The pipeline will be automatically be executed.
