param location string
param resourceToken string
param tags object
param vmAdminUsername string
@secure()
param vmAdminPassword string


var abbrs = loadJsonContent('abbreviations.json')
var subnetName = '${abbrs.networkVirtualNetworksSubnets}${resourceToken}'

@description('SKU for the public IP visit https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-ip-addresses-overview-arm#sku for more info.')
param publicIpAddressSku string = 'Basic'

@description('Disk type for your VM storage. Check https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disks-types for reference.')
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param osDiskType string = 'Standard_LRS'

@description('The URL where the install script is located. If you do not require additional plugins or custom installs leave the default')
param scriptLocation string = 'https://raw.githubusercontent.com/crazy4pi314/littlest-jupyterhub-vm/main/scripts/vm-install.sh'

@description('Data disk size - this is attached to your VM for storage.')
@allowed([
  1024
  2048
  4096
  8192
  16384
  32767
])
param dataDiskSize int = 1024

@description('Virtual machine name.')
param virtualMachineName string = 'ljh-vm'//'${abbrs.computeVirtualMachines}${resourceToken}'

@description('Your Virtual Machine size see https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-general')
@allowed([
  'CPU-8GB'
  'CPU-14GB'
  'CPU-16GB'
  'CPU-28GB'
  'CPU-32GB'
  'CPU-64GB'
  'CPU-112GB'
  'CPU-128GB'
  'CPU-256Gb'
  'CPU-432Gb'
])
param virtualMachineSize string = 'CPU-64GB'

var vmSize = {
  'CPU-8GB': 'Standard_F4s_v2'
  'CPU-14GB': 'Standard_DS3_v2'
  'CPU-16GB': 'Standard_D4s_v3'
  'CPU-28GB': 'Standard_DS4_v2'
  'CPU-32GB': 'Standard_F4s_v2'
  'CPU-64GB': 'Standard_D16s_v3'
  'CPU-112GB': 'Standard_DS14-4_v2'
  'CPU-128GB': 'Standard_E16s_v3'
  'CPU-256Gb': 'Standard_E32_v3'
  'CPU-432Gb': 'Standard E64_v3'
}

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '22_04-lts-gen2'
])
param ubuntuOSVersion string = '22_04-lts-gen2'



resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: '${abbrs.networkNetworkSecurityGroups}${resourceToken}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTP'
        properties: {
          priority: 300
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          priority: 310
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'SSH'
        properties: {
          priority: 340
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${abbrs.networkVirtualNetworks}${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
  resource subnet 'subnets' existing = {
    name: subnetName
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: '${abbrs.networkPublicIPAddresses}${resourceToken}'
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: publicIpAddressSku
    tier: 'Regional'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2019-06-01' = {
  name: '${abbrs.networkNetworkInterfaces}${resourceToken}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: virtualNetwork::subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
      //id: nsgId
    }
  }
  dependsOn: [
    //publicIpAddress
    // virtualNetwork
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  location: location
  sku: {
    name: osDiskType
  }
  kind: 'Storage'
  properties: {}
}

resource dataDiskResources 'Microsoft.Compute/disks@2018-06-01' = {
  name: '${abbrs.computeDisks}${resourceToken}'
  location: location
  sku: {
    name: osDiskType
  }
  properties: {
    diskSizeGB: dataDiskSize
    creationData: {
      createOption: 'empty'
    }
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: virtualMachineName
  location: location
  tags: {
    displayName: virtualMachineName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize[virtualMachineSize]
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: ubuntuOSVersion
        version: 'latest'
      }
      dataDisks: [
        {
          name: dataDiskResources.name
          lun: 0
          createOption: 'attach'
          managedDisk: {
            id: dataDiskResources.id
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
  }
  dependsOn: [
    storageAccount
  ]
}

resource installScript 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: virtualMachine
  name: 'installScript'
  location: location
  tags: {
    displayName: 'Execute Jupyter install script'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'basename ${scriptLocation} | xargs -I % bash "%" ${vmAdminUsername}'
      fileUris: [
        scriptLocation
      ]
    }
  }
  dependsOn: [
  ]
}

output vmAdminUsername string = vmAdminUsername
