# ADS: PHP2Shell post exploitation web server shell spawn

<!-- ads:fixed -->
| Field | Value |
| --- | --- |
| Rule file | `Rules/php2shell_web_server_shell_spawn.yml` |
| Rule id | 105ef7ed-69ee-47e8-b988-bbd2cb47cd73 |
| Severity | Medium |
| Owner | zdr4k |
| Rule version | 1.0.0 |
<!-- /ads:fixed -->

## Goal
<!-- ads:fixed -->
Detects suspected PHP2Shell style post exploitation behavior where a web server process starts a shell with -c and runs reconnaissance or payload staging commands such as id, whoami, curl, wget, or base64 -d. This indicates likely remote code execution leading to command execution on internet facing infrastructure. It does not detect the initial exploit request itself when no request level signature is available.
<!-- /ads:fixed -->

## Categorization
<!-- ads:fixed -->
InitialAccess: T1190

Execution: T1059
<!-- /ads:fixed -->

## Strategy Abstract
<!-- ads:draft -->
The rule reads the `DeviceProcessEvents` table and looks for a shell (sh, bash, dash, zsh or ksh) started by a web server process: apache2, httpd, nginx, php-cgi, frankenphp, litespeed, or any process whose name starts with php-fpm or lsphp. The shell must run with `-c` and its command line must contain whoami, curl, wget, `base64 -d` or the `id` command. It looks back one hour and runs every hour. Each matching process raises one alert with the host, the account that started the web server process and the full command line.

The idea is behavior over indicators. PHP2Shell is the name used for two unauthenticated remote code execution flaws in PHP core (CVE-2026-109618 and CVE-2026-109619). Public sources describe no indicators of compromise and no log signature for the exploit request, so the rule watches what an attacker does once code runs.
<!-- /ads:draft -->

## Technical Context
<!-- ads:draft -->
The data comes from Microsoft Defender for Endpoint process telemetry on Linux web servers, available in Sentinel as `DeviceProcessEvents`. The fields that matter are `InitiatingProcessFileName` (the web server process), `FileName` (the shell that was started), `ProcessCommandLine` (what the shell was told to run), `DeviceName` and `InitiatingProcessAccountName`.

On Linux the web server usually runs as a service account such as www-data, which has no UPN, so the rule maps the account by name and the host by device name. The process telemetry carries no remote IP for a child of a web server, so there is no IP entity.

A web server worker normally serves requests and does not start a shell. When it does, the command line shows what the application, or an attacker, asked the system to do.
<!-- /ads:draft -->

## Blind Spots and Assumptions
<!-- ads:draft -->
The rule assumes Defender for Endpoint is installed on the Linux web servers and that process events reach the workspace. A server without the agent is invisible to it.

It only sees a shell started with `-c` and one of the listed strings. It does not see other interpreters called directly, such as python or perl, a reverse shell built without these strings, other spellings such as `base64 --decode`, or commands hidden by encoding. It does not see a web shell being written to disk, so a dropped file is not detected here. It does not see the exploit request, and it fires only after code has already run.

The web server list is fixed. A renamed or custom process, or a worker started by another supervisor, is missed. The query period equals the run frequency, so events that reach the table late, because of ingestion delay, can be missed. Suppression is off and the trigger threshold is 0, so every matching process raises its own alert.
<!-- /ads:draft -->

## False Positives
<!-- ads:draft -->
Applications legitimately run shell commands from web workers. Common cases are CMS cron jobs, plugins that call curl or wget to fetch updates, health checks and monitoring scripts that run id or whoami, deployment hooks, and control panels. A `curl` or `wget` alone is the weakest signal, which is why the severity is Medium.

To tell them apart, compare the parent and the command line with what the application is known to do, check where curl or wget connects and whether the destination is expected, and look at whether the same command appears on many hosts at regular times. A command that runs once on one server, uses `base64 -d` or pipes a download into a shell deserves more attention.
<!-- /ads:draft -->

## Validation
<!-- ads:draft -->
1. On a test Linux server with Defender for Endpoint and PHP-FPM, create a harmless PHP page that runs `sh -c "id"` through `shell_exec`. Do not try to exploit the CVEs.
2. Request the page through the web server.
3. Run the query in Logs with a wider time range to confirm the event is in `DeviceProcessEvents`.
4. Enable the rule on the test workspace and wait for the next run (up to one hour).
5. Confirm an alert is created with the device name, the account name and the full command line.
<!-- /ads:draft -->

## Priority
<!-- ads:fixed -->
Medium. The behavior is rarely legitimate on a hardened server, but applications that start shells from web workers are common, so the rule needs tuning before a higher severity is justified. Raise it for internet facing hosts that have no known shell hooks.
<!-- /ads:fixed -->

## Response
<!-- ads:draft -->
1. Identify the host and the web application, and check whether the command is known behavior of that application.
2. Read the parent process and the command line, then list other commands run by the same account on the host over the last 24 hours.
3. Look for follow up activity on the same host: new files under the web root, outbound connections and downloaded payloads.
4. Check the installed PHP version against the fixed releases (8.5.12, 8.4.27, 8.3.36 and 8.2.35) and patch if it is behind.
5. If the command is not explained, treat the host as compromised and follow the incident response process. Preserve the web server and PHP logs.
<!-- /ads:draft -->

## Additional Resources
<!-- ads:fixed -->
[Elastic Security Labs, php2shell detection coverage](https://www.elastic.co/security-labs/threat-command/php2shell-php-rce-detection)

[Help Net Security, PHP2Shell patched](https://www.helpnetsecurity.com/2026/10/21/php2shell-php-vulnerabilities-patched-cve-2026-109618-cve-2026-109619/)
<!-- /ads:fixed -->