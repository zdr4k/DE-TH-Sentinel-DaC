// Detection: Azure role assignment created
// Data source: AzureActivity
// MITRE: Persistence / T1098

param workspace string = 'log-analyst-de-lab'

var ruleId = 'd3c1a7f2-6b4e-4c8a-9e51-2f7a0b8c4d16'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspace
}

resource rule 'Microsoft.SecurityInsights/alertRules@2025-03-01' = {
  name: ruleId
  scope: logAnalyticsWorkspace
  kind: 'Scheduled'

  properties: {
    displayName: 'Azure role assignment created'
    description: 'Detects successful role assignment writes in the subscription activity log.'

    enabled: true
    severity: 'Medium'

    query: '''
AzureActivity
| where TimeGenerated > ago(1h)
| where OperationNameValue =~ "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE"
| where ActivityStatusValue =~ "Success"
| project TimeGenerated, Caller, CallerIpAddress, ResourceGroup, SubscriptionId, _ResourceId
'''

    queryFrequency: 'PT15M'
    queryPeriod: 'PT1H'

    triggerOperator: 'GreaterThan'
    triggerThreshold: 0

    suppressionEnabled: false
    suppressionDuration: 'PT1H'

    tactics: [
      'Persistence'
    ]

    techniques: [
      'T1098'
    ]

    incidentConfiguration: {
      createIncident: true
    }

    entityMappings: [
      {
        entityType: 'Account'
        fieldMappings: [
          {
            identifier: 'FullName'
            columnName: 'Caller'
          }
        ]
      }
      {
        entityType: 'IP'
        fieldMappings: [
          {
            identifier: 'Address'
            columnName: 'CallerIpAddress'
          }
        ]
      }
    ]
  }
}
