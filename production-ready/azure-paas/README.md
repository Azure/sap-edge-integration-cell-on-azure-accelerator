# SAP Edge Integration Cell on Azure - Production PaaS Delta (PostgreSQL and Redis)

This page defines the Azure PaaS components that should be added for a production SAP Edge Integration Cell (EIC) setup.

Scope of this document:

- Focus only on Azure Database for PostgreSQL and Azure Managed Redis
- Describe the production delta compared to a quickstart-style deployment
- Provide practical provisioning guidance and validation checks

Out of scope:

- AKS cluster design and provisioning (covered in other files)
- SAP BTP entitlement and ELM wizard details

## Why This Delta Exists

Quickstart deployments optimize for fast setup. Production deployments optimize for:

- high availability
- security and private connectivity
- backup and disaster recovery
- operational visibility and controlled change

For SAP EIC, PostgreSQL and Redis are key shared services. Running them with production controls reduces platform risk and improves recovery posture.

## Production Delta Summary

| Area | Quickstart intent | Production delta required |
|---|---|---|
| PostgreSQL compute tier | Minimal/low-cost | General Purpose or higher, zone-redundant where available |
| PostgreSQL connectivity | Public allowed in PoC | Private endpoint only, public network disabled |
| PostgreSQL durability | Basic defaults | PITR backups, longer retention, tested restore runbook |
| PostgreSQL security | Basic auth | TLS enforced, strong admin secret rotation, optional Entra auth |
| Redis tier | Basic cache setup | Standard or Premium/Enterprise with SLA and persistence strategy |
| Redis connectivity | Open/simple networking | Private endpoint only, public network disabled |
| Redis resilience | Single node acceptable in PoC | Replication and zone-aware topology (SKU permitting) |
| Ops and monitoring | Ad-hoc checks | Alerting, log retention, capacity and failover drills |

## Reference Target State

Use the following target state for production.

### PostgreSQL (Azure Database for PostgreSQL Flexible Server)

- Deployment mode: Flexible Server
- Tier: General Purpose (or better based on workload)
- High availability: Zone-redundant HA where supported in region
- Storage: Premium SSD-backed managed storage, auto-grow enabled
- Network: Private endpoint only, public access disabled
- Security:
	- TLS required
	- Strong admin credentials in Azure Key Vault
	- Optional Microsoft Entra authentication for admin/operator access
- Data protection:
	- Automatic backups with retention aligned to business RPO
	- Point-in-time restore validation in non-production on a schedule

### Redis (Azure Managed Redis)

- SKU: choose at least a production-capable tier with SLA support
- Capacity: sized for peak throughput and failover headroom
- Network: Private endpoint only, public access disabled
- Security:
	- TLS enforced
	- Access keys in Azure Key Vault and rotated
	- Use ACL/users if selected SKU supports it
- Resilience:
	- Replication enabled according to selected tier
	- Zone-aware or multi-zone option where available
- Data protection:
	- Persistence strategy enabled if business requires warm recovery

## Provisioning Checklist

Use this as a release gate before onboarding SAP EIC runtime.

### 1. Network and Name Resolution

- [ ] Private endpoints created for PostgreSQL and Redis
- [ ] Public network access disabled on both services
- [ ] Private DNS zone links in place for all required virtual networks
- [ ] Connectivity validation from workload network to both private endpoints

### 2. Security Baseline

- [ ] TLS required for PostgreSQL and Redis clients
- [ ] Secrets stored in Key Vault (not in Terraform state vars files)
- [ ] Key rotation process documented and tested
- [ ] RBAC scoped with least privilege for operators and automation

### 3. Reliability and Recovery

- [ ] PostgreSQL backup retention configured to match RPO policy
- [ ] PostgreSQL point-in-time restore tested and timed
- [ ] Redis failover behavior tested during controlled maintenance
- [ ] Redis persistence settings reviewed against RTO objectives

### 4. Observability and Operations

- [ ] Diagnostic settings enabled to Log Analytics / SIEM
- [ ] Alerts configured for CPU, memory, storage, connections, and failures
- [ ] Capacity thresholds defined with clear scale-up triggers
- [ ] Operational runbook published for patching and incident response

## Sizing Guidance (Starting Point)

Final sizing must be validated with real SAP EIC traffic profile, iFlow mix, and concurrency.

### PostgreSQL

- Start with General Purpose class and enough vCores for sustained write/read load
- Use storage auto-grow and monitor IOPS, storage latency, and connection saturation
- Scale compute before saturation events; avoid running close to max connections

### Redis

- Size primarily from working set memory and peak request rate
- Reserve headroom for failover and traffic bursts
- Monitor memory fragmentation and eviction metrics to prevent latency spikes

## Validation Commands (Azure CLI)

These commands are examples to confirm production settings after provisioning.

```bash
# PostgreSQL Flexible Server: verify public network access is disabled
az postgres flexible-server show \
	--name <postgres_server_name> \
	--resource-group <resource_group> \
	--query "network.publicNetworkAccess"

# Redis: verify public network access is disabled
az redis show \
	--name <redis_name> \
	--resource-group <resource_group> \
	--query "publicNetworkAccess"

# Inspect private endpoint connections for PostgreSQL
az network private-endpoint-connection list \
	--name <postgres_server_name> \
	--resource-group <resource_group> \
	--type "Microsoft.DBforPostgreSQL/flexibleServers"

# Inspect private endpoint connections for Redis
az network private-endpoint-connection list \
	--name <redis_name> \
	--resource-group <resource_group> \
	--type "Microsoft.Cache/Redis"
```

## Recommended Rollout Sequence

1. Provision PostgreSQL with private connectivity, HA, backup policy, and monitoring.
2. Provision Redis with private connectivity, replication/persistence strategy, and monitoring.
3. Validate connectivity and policy controls from the application network.
4. Execute recovery and failover validation drills.
5. Only then proceed with SAP EIC runtime onboarding.

## Decision Log Template

Record these decisions per environment (dev, test, prod):

| Decision | Example |
|---|---|
| PostgreSQL tier and size | GP, 4 vCores, zone-redundant |
| PostgreSQL backup retention | 14 days |
| Redis tier and capacity | Premium, 6 GB, replication enabled |
| Private DNS design | Central private DNS, linked VNets |
| Key rotation cadence | Every 90 days |
| Recovery test cadence | Quarterly |

## Related References

- [AKS baseline references](../aks/README.md#aks-baseline-references)
- [Knowledge Base: Architecture Overview](../../knowledge-base/architecture.md)
- [Knowledge Base: Prerequisites and sizing](../../knowledge-base/prerequisites.md)
- [Knowledge Base: Operations runbook](../../knowledge-base/runbooks/operations.md)
- [Production-ready AKS guidance](../aks/README.md)
