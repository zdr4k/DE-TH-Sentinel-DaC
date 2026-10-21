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
The rule only works if Azure Activity logs are being ingested into Sentinel. It only detects successful delete events, not failed attempts or indirect ways to reduce logging that use other operations. The query window is one hour, so events outside that period are not evaluated. The rule assumes `Caller` and `CallerIpAddress` are populated in the event.
<!-- /ads:draft -->

## False Positives
<!-- ads:draft -->
Legitimate administration can produce this alert during planned logging changes, environment teardown, or infrastructure-as-code updates. Benign events are usually associated with approved change windows and expected automation identities. Compare the caller, source IP, and target resource with known maintenance activity before escalating.
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
