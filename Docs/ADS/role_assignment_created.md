# ADS: Azure role assignment created

<!-- ads:fixed -->
| Field | Value |
| --- | --- |
| Rule file | `Rules/role_assignment_created.yml` |
| Rule id | d3c1a7f2-6b4e-4c8a-9e51-2f7a0b8c4d16 |
| Severity | Medium |
| Owner | Kelvin Santos |
| Rule version | 1.0.0 |
<!-- /ads:fixed -->

## Goal
<!-- ads:fixed -->
Identifies successful role assignment writes in the Azure Activity log, which means a user or service principal was granted a new role in the Azure environment.
<!-- /ads:fixed -->

## Categorization
<!-- ads:fixed -->
Persistence: T1098
PrivilegeEscalation: T1098
<!-- /ads:fixed -->

## Strategy Abstract
<!-- ads:draft -->
This detection monitors the AzureActivity table for successful role assignment write operations. It filters to events in the last hour where `OperationNameValue` equals `MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE` and `ActivityStatusValue` is `Success`. The analytics rule runs every 15 minutes and alerts on any match. Alert results include the initiating caller, source IP, resource group, subscription, and affected resource id.
<!-- /ads:draft -->

## Technical Context
<!-- ads:draft -->
The rule uses Azure control-plane telemetry in `AzureActivity`. `OperationNameValue` indicates the exact management operation and `ActivityStatusValue` confirms it completed successfully. `Caller` and `CallerIpAddress` are mapped as entities for investigation and triage. `ResourceGroup`, `SubscriptionId`, and `_ResourceId` provide the target scope where the new permission was assigned.
<!-- /ads:draft -->

## Blind Spots and Assumptions
<!-- ads:draft -->
This rule assumes Azure Activity logging is enabled and ingested; without that data source, role assignment writes are not visible to the query. `query_period` is 1 hour and `query_frequency` is 15 minutes, so one event can be evaluated in 4 runs. With `suppression_enabled` set to false and incident grouping disabled, those repeated evaluations are not absorbed and may generate duplicate alerts. The rule also uses `trigger_operator: GreaterThan` with `trigger_threshold: 0`, so any single matching write can trigger an alert on a table that may include frequent legitimate administration.
<!-- /ads:draft -->

## False Positives
<!-- ads:draft -->
Expected IAM administration and approved automation can legitimately create role assignments. Common benign cases include onboarding users, service principal provisioning, and infrastructure deployments. Because the same event can be re-evaluated in 4 runs and duplicate absorption is disabled, one approved change can raise multiple alerts. Validate alerts against planned access changes, approved identities, and repeated matches with the same caller and target scope before treating activity as suspicious.
<!-- /ads:draft -->

## Validation
<!-- ads:draft -->
1. In a test subscription, assign a role to a test principal on a known resource scope.
2. Ensure the assignment action completes successfully and is recorded in Azure Activity.
3. Wait for the rule to run (up to 15 minutes).
4. Verify an alert is generated with `Caller`, `CallerIpAddress`, `ResourceGroup`, `SubscriptionId`, and `_ResourceId` populated from the assignment event.
<!-- /ads:draft -->

## Priority
<!-- ads:fixed -->
Medium. New role assignments can indicate persistence or privilege escalation, but many environments also generate legitimate administrative role changes.
<!-- /ads:fixed -->

## Response
<!-- ads:draft -->
Confirm whether the role assignment was authorized by reviewing change records and the identity in `Caller`. Investigate additional actions by the same `Caller` and `CallerIpAddress` to detect broader privilege changes. Determine the scope of access granted from the affected `SubscriptionId` and `_ResourceId` and involve the resource owner if needed. Escalate according to incident procedures when the change cannot be validated as approved.
<!-- /ads:draft -->

## Additional Resources
<!-- ads:fixed -->
None
<!-- /ads:fixed -->
