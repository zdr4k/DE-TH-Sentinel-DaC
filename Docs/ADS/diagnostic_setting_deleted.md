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
This rule reads `AzureActivity` and looks for successful diagnostic setting deletions. It filters for `OperationNameValue` equal to `MICROSOFT.INSIGHTS/DIAGNOSTICSETTINGS/DELETE` and `ActivityStatusValue` equal to `Success`. The lookback window is 1 hour and the schedule is every 15 minutes. The trigger is `GreaterThan 0`, so any matching result creates an alert.
<!-- /ads:draft -->

## Technical Context
<!-- ads:draft -->
The data source is the `AzureActivity` table. The query uses `OperationNameValue` to identify the delete action and `ActivityStatusValue` to keep only successful operations. It projects `Caller`, `CallerIpAddress`, `ResourceGroup`, `SubscriptionId`, and `_ResourceId` for investigation context. Entity mappings use `Caller` for `Account.FullName` and `CallerIpAddress` for `IP.Address`, and both columns are returned by the query.
<!-- /ads:draft -->

## Blind Spots and Assumptions
<!-- ads:analyst -->
The rule assumes Azure Activity logging is enabled and ingested; without that connector and diagnostic pipeline, no events are available to detect. `query_period` is 1 hour and `query_frequency` is 15 minutes, so the same event remains in scope for 4 runs. Because `suppression_enabled` is false and incident grouping is disabled, repeated evaluations are not absorbed and can create duplicate alerts. The rule also uses `trigger_operator: GreaterThan` with `trigger_threshold: 0`, so any single matching event can fire an alert on this potentially noisy table.

Analyst note: reviewed on 21 October 2026 against the production workspace, repeated alerts confirmed during the test.
<!-- /ads:analyst -->

## False Positives
<!-- ads:draft -->
Legitimate admin work can trigger this rule, for example planned monitoring changes, environment teardown, or automation that recreates diagnostic settings. Because `query_period` is 1 hour and `query_frequency` is 15 minutes, one event can be evaluated in 4 runs. With suppression disabled and incident grouping disabled, those repeated evaluations are not absorbed and can produce duplicates. Since the threshold is `GreaterThan 0`, a single benign event is enough to alert.
<!-- /ads:draft -->

## Validation
<!-- ads:draft -->
1. In a test subscription, ensure a resource has a diagnostic setting.
2. Delete that diagnostic setting with an account that writes to `AzureActivity`.
3. Wait for the next run (up to 15 minutes).
4. Confirm an alert is generated for a successful delete operation.
5. Confirm alert context includes `Caller`, `CallerIpAddress`, `ResourceGroup`, `SubscriptionId`, and `_ResourceId`.
<!-- /ads:draft -->

## Priority
<!-- ads:fixed -->
High. Deleting diagnostic settings can stop security telemetry and reduce visibility during active malicious activity.
<!-- /ads:fixed -->

## Response
<!-- ads:draft -->
Check whether the delete was authorized in a change record. Review `Caller` and `CallerIpAddress` and pivot to nearby `AzureActivity` operations from the same actor for related control-plane changes. Verify whether diagnostic settings were restored and document the telemetry gap window. If the action is not expected, escalate through incident response.
<!-- /ads:draft -->

## Additional Resources
<!-- ads:fixed -->
None
<!-- /ads:fixed -->
