param name string
param location string

resource vmSubnetNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsg-vmsubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsg-bastion'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
          destinationPortRanges: ['8080','5701']
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          destinationPortRanges: ['22','3389']
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
          destinationPortRanges: ['8080','5701']
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

var subnetConfigurations = [
  {
    name: 'vmSubnet'
    addressPrefix: '172.16.1.0/24'
    nsgId: vmSubnetNsg.id
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '172.16.2.0/24'
    nsgId: bastionNsg.id
  }
  {
    name: 'aksSubnet'
    addressPrefix: '172.16.4.0/23'
    nsgId: null
  }
]

resource vnet 'Microsoft.Network/virtualNetworks@2019-12-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    subnets: [for (config,i) in subnetConfigurations: {
      name: config.name
      properties: {
        addressPrefix: config.addressPrefix
        networkSecurityGroup: config.nsgId != null ? {
          id: config.nsgId
        } : null
      }
    }]
  }
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: 'aksSubnet'
  parent: vnet
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: 'vmSubnet'
  parent: vnet
}

output name string = vnet.name
output id string = vnet.id
output vmSubnetId string = vmSubnet.id
output aksSubnetId string = aksSubnet.id
output aksSubnetName string = aksSubnet.name
