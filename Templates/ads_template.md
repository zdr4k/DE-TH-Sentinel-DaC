# ADS: {display_name}

<!-- ads:fixed -->
| Field | Value |
| --- | --- |
| Rule file | `Rules/{rule_file}.yml` |
| Rule id | {id} |
| Severity | {severity} |
| Owner | {meta.owner} |
| Rule version | {version} |
<!-- /ads:fixed -->

## Goal
<!-- ads:fixed -->
{description}
<!-- /ads:fixed -->

## Categorization
<!-- ads:fixed -->
MITRE ATT&CK, one line per tactic with its techniques, copied from `mitre_mapping`.
<!-- /ads:fixed -->

## Strategy Abstract
<!-- ads:draft -->
High level description of how the detection works: which table it reads, what it filters, the window and frequency, what it alerts on. Three to five sentences.
<!-- /ads:draft -->

## Technical Context
<!-- ads:draft -->
Data source, the fields the query uses and what they mean, what an analyst needs to know about the event before reading an alert.
<!-- /ads:draft -->

## Blind Spots and Assumptions
<!-- ads:draft -->
What this rule cannot see and what it assumes to be true (logging enabled, field populated, time window, who can bypass it).
<!-- /ads:draft -->

## False Positives
<!-- ads:draft -->
Known benign causes and how to tell them apart from malicious activity.
<!-- /ads:draft -->

## Validation
<!-- ads:draft -->
How to trigger this detection on purpose, step by step, and what the alert should look like.
<!-- /ads:draft -->

## Priority
<!-- ads:fixed -->
Severity from the rule, with one sentence on why that level fits.
<!-- /ads:fixed -->

## Response
<!-- ads:draft -->
First steps for the analyst who receives the alert. Guidance only, no destructive actions.
<!-- /ads:draft -->

## Additional Resources
<!-- ads:fixed -->
Links from `meta.references`. Write "None" when the list is empty.
<!-- /ads:fixed -->