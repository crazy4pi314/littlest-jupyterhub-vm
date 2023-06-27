param location string
param resourceToken string
param tags object
param adminUsername string
@secure()
param adminPassword string


var abbrs = loadJsonContent('abbreviations.json')

var networkSecurityGroupName = 'jupyter-vm-nsg'
var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)

var virtualNetworkName = '${abbrs.networkVirtualNetworks}${resourceToken}'
var subnetName = '${abbrs.networkVirtualNetworksSubnets}${resourceToken}'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
// var vnetId = resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
// var vnetId = virtualNetwork.id

var publicIPAddressName = 'jupyter-PublicIP'
// @description('SKU for the public IP visit https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-ip-addresses-overview-arm#sku for more info.')
param publicIpAddressSku string = 'Basic'

var nicName = 'jupyter-VMNic'
// var subnetRef = '${vnetId}/subnets/${subnetName}'

var storageAccountName = '${abbrs.storageStorageAccounts}${resourceToken}'
// @description('Disk type for your VM storage. Check https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disks-types for reference.')
// @allowed([
//   'StandardSSD_LRS'
//   'Standard_LRS'
//   'Premium_LRS'
// ])
param osDiskType string = 'Standard_LRS'

var dataDiskResourcesName = '${abbrs.computeDisks}${resourceToken}'
// @description('Data disk size - this is attached to your VM for storage.')
// @allowed([
//   1024
//   2048
//   4096
//   8192
//   16384
//   32767
// ])
param dataDiskSize int = 1024

// @description('Virtual machine name. Use a meaningful name.')
param virtualMachineName string = 'ljh-vm'//'${abbrs.computeVirtualMachines}${resourceToken}'
// @description('Your Virtual Machine size see https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-general')
// @allowed([
//   'CPU-8GB'
//   'CPU-14GB'
//   'CPU-16GB'
//   'CPU-28GB'
//   'CPU-32GB'
//   'CPU-64GB'
//   'CPU-112GB'
//   'CPU-128GB'
//   'CPU-256Gb'
//   'CPU-432Gb'
// ])
param virtualMachineSize string = 'CPU-64GB'

// @description('Username for admin user.')
// param adminUsername string

// @description('Root password, you need this to access the admin functions.')
// @secure()
// param adminPassword string

// @description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
// @allowed([
//   '18.04-LTS'
//   '20.04-LTS'
//   '22_04-lts-gen2'
// ])
param ubuntuOSVersion string = '22_04-lts-gen2'
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

// @description('The URL where the install script is located. If you do not require additional plugins or custom installs leave the default')
param scriptLocation string = 'https://raw.githubusercontent.com/trallard/TLJH-azure-button/master/scripts/install.sh'


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: networkSecurityGroupName
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
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          // delegations: [
          //   {
          //     name: 'subnet-delegation-${resourceToken}'
          //     properties: {
          //       serviceName: 'Microsoft.Web/serverFarms'
          //     }
          //   }
          // ]
        }
      }
    ]
  }
  resource subnet 'subnets' existing = {
    name: subnetName
  }
  // resource webappSubnet 'subnets' existing = {
  //   name: webappSubnetName
  // }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: publicIPAddressName
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
  name: nicName
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
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIPAddressName)
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroup
    publicIpAddress
    // virtualNetwork
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: osDiskType
  }
  kind: 'Storage'
  properties: {}
}

resource dataDiskResources 'Microsoft.Compute/disks@2018-06-01' = {
  name: dataDiskResourcesName
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
          name: dataDiskResourcesName
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
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
  dependsOn: [
    // dataDiskResources

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
      commandToExecute: 'basename ${scriptLocation} | xargs -I % bash "%" ${adminUsername}'
      fileUris: [
        scriptLocation
      ]
    }
  }
  dependsOn: [
    virtualMachine
  ]
}

output adminUsername string = adminUsername
