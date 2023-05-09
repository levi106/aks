targetScope = 'subscription'

param resourceGroupName string = 'rg-aks'
param location string = deployment().location
param aksVersion string = '1.25.6'
param adminUsername string = 'azureuser'
@secure()
param adminPublicKey string
param sqlAdminUsername string = 'sqladmin'
@secure()
param sqlAdminPassword string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module sql 'modules/sql.bicep' = {
  name: 'sqldb'
  scope: rg
  params: {
    sqlServerName: 'sql-${uniqueString(rg.id)}'
    dbName: 'db-${uniqueString(rg.id)}'
    location: location
    adminUsername: sqlAdminUsername
    adminPassword: sqlAdminPassword
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: take(replace(toLower('st${uniqueString(rg.id)}'),'-',''), 24)
    location: location
  }
}

module la 'modules/la.bicep' = {
  name: 'la'
  scope: rg
  params: {
    name: 'la-${uniqueString(rg.id)}'
    location: location
  }
}

module ai 'modules/ai.bicep' = {
  name: 'ai'
  scope: rg
  params: {
    name: 'ai-${uniqueString(rg.id)}'
    location: location
    laId: la.outputs.id
  }
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnet'
  scope: rg
  params: {
    name: 'vnet'
    location: location
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vm'
  scope: rg
  params: {
    name: 'vm'
    location: location
    subnetId: vnet.outputs.vmSubnetId
    privateIPAddress: '172.16.1.10'
    adminUsername: adminUsername
    publicKey: adminPublicKey
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks'
  scope: rg
  params: {
    name: 'aks'
    location: location
    laId: la.outputs.id
    subnetId: vnet.outputs.aksSubnetId
    systemNodeCount: 1
    aksVersion: aksVersion
  }
}

module roleAssignment 'modules/subnetRoleAssignment.bicep' = {
  name: 'roleassignment'
  scope: rg
  params: {
    vnetName: vnet.name
    subnetName: vnet.outputs.aksSubnetName
    principalId: aks.outputs.principalId
  }
}
