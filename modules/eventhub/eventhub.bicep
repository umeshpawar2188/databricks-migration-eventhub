//Parameters

@allowed([
  'Basic'
  'Standard'
])
param eventHubSku string 

@description('')
param eHRuleName string

param ctrlDeployEventHub bool

//Variables

var randomString = substring(guid(resourceGroup().id), 0, 6)

var eventHubNamespaceName = 'streamdata-${randomString}-ns'

var location = resourceGroup().location

var eventHubName = 'streamdata-${randomString}-ns'

//Resources

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = if(ctrlDeployEventHub) {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHubNamespace_eventHubName 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = if(ctrlDeployEventHub && eventHubSku == "Standard") {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 2
    partitionCount: 1
  }
  dependsOn: [
    eventHubNamespace
  ]
}
else {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
  }
  dependsOn: [
    eventHubNamespace
  ]
}


resource eventHubName_rule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-01-01-preview' = if(ctrlDeployEventHub) {
  name: '${eventHubNamespaceName}/${eventHubName}/${eHRuleName}'
  properties: {
    rights: [
      'Send'
      'Listen'
    ]
  }
  dependsOn: [
    eventHubNamespace_eventHubName
  ]
}

//Outputs

output eventhubResourceId string = eventHubNamespace.id

output eventHubResourceOp string = 'Name: ${eventHubNamespace.name} - Type: ${eventHubNamespace.type} || Name: ${eventHubNamespace_eventHubName.name} - Type: ${eventHubNamespace_eventHubName.type} || Name: ${eventHubName_rule.name} - Type: ${eventHubName_rule.type}'
