# AWS deployment (high-level)

This repository intentionally **does not** include the full infrastructure-as-code or server hardening scripts.

In the full project, deployment was done on **AWS** using:
- VPC with **Public + Private** subnets
- EC2 (public) for reverse-proxy / monitoring / CI
- EC2 (private) for the API + MLflow
- Security Groups to restrict inbound access (SSH only from trusted IPs; services via 80/443)

No public IPs, hostnames, or credentials are stored in this repo.
