# ADS documents

One file per rule, named after the rule file. To get a draft, comment on the pull request:

`@copilot write the ADS for Rules/<rule>.yml following the repo instructions`

Copilot commits to the PR branch. Review the diff like any other change.

Marker rules
- `ads:fixed`: copied from the rule YAML, regenerated when the rule changes.
- `ads:draft`: written by the agent, will be rewritten on the next request.
- Edit a draft section and change its marker to `ads:analyst`. The agent will not touch it again.