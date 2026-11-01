# ADS: PowerShell encoded command execution

<!-- ads:fixed -->
| Field | Value |
| --- | --- |
| Rule file | `Rules/powershell_encoded_command.yml` |
| Rule id | 30eeb49f-ed69-4406-a973-f85a10c872c8 |
| Severity | Medium |
| Owner | zdr4k |
| Rule version | 1.0.0 |
<!-- /ads:fixed -->

## Goal
<!-- ads:fixed -->
Detects PowerShell launched with an encoded command argument (-EncodedCommand / -enc / -e). Encoding the command is a common way to obscure malicious PowerShell from casual inspection and from simple command-line string matching. Reads Sysmon process creation events (Event ID 1) collected from the lab endpoint. It does not by itself confirm intent, since encoded commands have legitimate uses.
<!-- /ads:fixed -->

## Categorization
<!-- ads:fixed -->
Execution: T1059
<!-- /ads:fixed -->

## Strategy Abstract
<!-- ads:draft -->
This rule reads the `Event` table and filters to Sysmon process creation events (`Source` equals `Microsoft-Windows-Sysmon` and `EventID` equals `1`) in the last hour. It parses `EventData` XML, extracts process fields, and keeps events where the process image ends with `powershell.exe` or `pwsh.exe`. It then looks for encoded command arguments (`-EncodedCommand`, `-enc`, or ` -e `) in `CommandLine`. The rule runs hourly with a one-hour lookback and creates one alert per matching event.
<!-- /ads:draft -->

## Technical Context
<!-- ads:draft -->
The detection depends on Windows SecurityEvent-style `Event` ingestion that includes Sysmon Event ID 1 records. The query uses `TimeGenerated`, `Source`, `EventID`, `EventData`, and `Computer` from the table, then extracts `Image`, `CommandLine`, `ParentImage`, and `User` from XML fields inside `EventData`. It maps `UserName` and `Computer` as entities to support account and host pivots during triage.

Analysts should treat encoded PowerShell usage as suspicious behavior that still needs context. Many attacks use encoded payloads to hide intent, but administrators and automation tooling can also use encoded commands for legitimate scripting.
<!-- /ads:draft -->

## Blind Spots and Assumptions
<!-- ads:draft -->
The rule assumes Sysmon is installed, configured to log process creation (Event ID 1), and that those events are ingested into the `Event` table. If Sysmon is absent, misconfigured, or logs arrive in another table, this detection will miss activity.

The query only matches explicit encoded-argument forms listed in the rule. Attackers can evade it by avoiding these flags, using alternate execution methods, or launching other interpreters. It also only checks `powershell.exe` and `pwsh.exe` image suffixes.

`query_period` equals `query_frequency` (1 hour), so late-ingested events can be missed. `incident_configuration.grouping_enabled` is false, so duplicate alert consolidation is not absorbed at incident grouping level. `trigger_operator` is `GreaterThan` with `trigger_threshold` 0, so any single matching event triggers an alert.
<!-- /ads:draft -->

## False Positives
<!-- ads:draft -->
Legitimate IT administration, software deployment tools, endpoint management scripts, and red-team simulations can run encoded PowerShell commands. Build and orchestration pipelines may also pass encoded payloads for reliability across shells.

To reduce noise, validate whether the user, parent process, host role, and command timing are expected. Repeated encoded commands from unusual parent processes, unexpected user contexts, or non-management endpoints are higher risk than known automation accounts.
<!-- /ads:draft -->

## Validation
<!-- ads:draft -->
1. On a test Windows endpoint with Sysmon enabled, run a harmless encoded command such as `powershell -enc <base64("Write-Host test")>`.
2. Confirm a Sysmon Event ID 1 entry is ingested into the `Event` table with `Image`, `CommandLine`, `ParentImage`, and user details in `EventData`.
3. Enable the rule in a test workspace and wait for the next scheduled run (up to one hour).
4. Verify an alert is produced with `TimeGenerated`, `Computer`, `UserName`, `ParentImage`, `Image`, and `CommandLine`.
<!-- /ads:draft -->

## Priority
<!-- ads:fixed -->
Medium. Encoded PowerShell execution is a common attacker obfuscation method, but it is also used by legitimate administration and automation in many environments.
<!-- /ads:fixed -->

## Response
<!-- ads:draft -->
1. Review the full command line, parent process, and user context to determine whether encoded execution is expected.
2. Pivot on the same host and account for additional suspicious process launches, script block activity, or network connections around the alert time.
3. Decode the encoded payload in a safe analysis environment and assess intent before taking containment actions.
4. If the activity is unapproved or malicious, isolate the host per incident process and investigate persistence or credential access follow-on behavior.
<!-- /ads:draft -->

## Additional Resources
<!-- ads:fixed -->
[MITRE ATT&CK: Command and Scripting Interpreter](https://attack.mitre.org/techniques/T1059/001/)
<!-- /ads:fixed -->

<!-- ADS writer note: Wrote all ads:draft sections (Strategy Abstract, Technical Context, Blind Spots and Assumptions, False Positives, Validation, Response). No analyst-owned sections were present to preserve. Uncertainty: none. -->
