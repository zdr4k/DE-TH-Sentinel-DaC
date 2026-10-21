# ADS: Azure diagnostic setting deleted

<!-- ads:fixed -->
| Field | Value |
| --- | --- |
| Rule file | `Rules/diagnostic_setting_deleted.yml` |
| Rule id | 31ae3148-3ec0-40d3-8343-0a9a6cda9394 |
| Severity | High |
| Owner | Kelvin Santos |
| Rule version | 1.0.0 |
<!-- /ads:fixed -->

## Goal
<!-- ads:fixed -->
Identifies successful deletions of diagnostic settings in the Azure Activity log. Removing a diagnostic setting stops logs from reaching the workspace, which an attacker can use to hide activity.
<!-- /ads:fixed -->

## Categorization
<!-- ads:fixed -->
DefenseEvasion: T1562
<!-- /ads:fixed -->

## Strategy Abstract
<!-- ads:draft -->
This detection reads the AzureActivity table and looks for successful delete operations on diagnostic settings. It filters to events from the last hour where `OperationNameValue` equals `MICROSOFT.INSIGHTS/DIAGNOSTICSETTINGS/DELETE` and `ActivityStatusValue` is `Success`. The rule runs every 15 minutes and triggers on any matching event. Each alert contains the caller identity, source IP, resource group, subscription, and resource id of the affected target.
<!-- /ads:draft -->

## Technical Context
<!-- ads:draft -->
The data source is Azure Activity logs in the `AzureActivity` table. `OperationNameValue` identifies the control-plane action and `ActivityStatusValue` confirms whether the action succeeded. `Caller` and `CallerIpAddress` map to the alert entities and help tie the action to an identity and origin. `ResourceGroup`, `SubscriptionId`, and `_ResourceId` identify what resource lost diagnostic logging.
<!-- /ads:draft -->

## Blind Spots and Assumptions
<!-- ads:draft -->
The rule assumes Azure Activity logging is enabled and ingested; without that connector and diagnostic pipeline, no events are available to detect. `query_period` is 1 hour and `query_frequency` is 15 minutes, so the same event remains in scope for 4 runs. Because `suppression_enabled` is false and incident grouping is disabled, repeated evaluations are not absorbed and can create duplicate alerts. The rule also uses `trigger_operator: GreaterThan` with `trigger_threshold: 0`, so any single matching event can fire an alert on this potentially noisy table.
<!-- /ads:draft -->

## False Positives
<!-- ads:draft -->
Legitimate administration can produce this alert during planned logging changes, environment teardown, or infrastructure-as-code updates. Because each matching event can be evaluated in 4 consecutive runs and duplicate absorption is disabled, benign actions can raise repeated alerts for the same operation. Approved change windows, expected automation identities, and repeated alerts with the same caller and target resource are indicators of a likely benign case.
<!-- /ads:draft -->

## Validation
<!-- ads:draft -->
1. In a test subscription, create a diagnostic setting on a resource that currently has one configured.
2. Delete that diagnostic setting using an account whose activity is logged to `AzureActivity`.
3. Wait for the next rule run (up to 15 minutes).
4. Confirm an alert is created and includes `Caller`, `CallerIpAddress`, `ResourceGroup`, `SubscriptionId`, and `_ResourceId` from the delete event.
<!-- /ads:draft -->

## Priority
<!-- ads:fixed -->
High. Deleting diagnostic settings can stop security telemetry and reduce visibility during active malicious activity.
<!-- /ads:fixed -->

## Response
<!-- ads:draft -->
Validate whether the deletion was planned by checking recent change records and the identity in `Caller`. If unplanned, review other Azure Activity events from the same `Caller` and `CallerIpAddress` for additional control-plane changes. Confirm whether logging was restored and identify any data gaps created while diagnostics were disabled. Preserve event details for incident handling and follow internal escalation procedures.
<!-- /ads:draft -->

## Additional Resources
<!-- ads:fixed -->
None
<!-- /ads:fixed -->
