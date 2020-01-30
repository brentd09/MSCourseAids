﻿function Initialize-DemoVMPair {

  $ResourceGroup = "demoresgroup"
  $Location = "EastUS"
  $vmName = "myVM"
  $VMs = @( 
    @{
      Name = 'demovm1'
      NICName = 'NIC1'
      VNet = 'vnet1'
      Subnet = 'subnet1'
      SecurityGroup = 'secgrp1'
      NSGName = 'myNetworkSecurityGroupRuleRDP1'
      PublicIP = 'publicip1'
      VNetPrefix  = '10.5.0.0/16'
      SubnetPrefix = '10.5.0.0/24'
    } , 
    @{
      Name = 'demovm2'
      NICName = 'NIC2'
      VNet = 'vnet2'
      Subnet = 'subnet2'
      SecurityGroup = 'secgrp2'
      NSGName = 'myNetworkSecurityGroupRuleRDP2'
      PublicIP = 'publicip2'
      VNetPrefix  = '100.50.0.0/16'
      SubnetPrefix = '100.50.0.0/24'  
    }
  )
  $Cred = Get-Credential -Message "Enter a username and password for the virtual machine."
  New-AzResourceGroup -Name $ResourceGroup -Location $Location
  foreach ($VM in $VMs) {
    $WarningPreference = 'SilentlyContinue'
    Write-Progress -Activity 'Creating Azure resources' -Status "Creating VNet and Subnet" -PercentComplete 20 
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $VM.Subnet -AddressPrefix $VM.SubnetPrefix 
    $VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VM.VNet -AddressPrefix $VM.VNetPrefix -Subnet $subnetConfig 
    Write-Progress -Activity 'Creating Azure resources' -Status "Creating Public IP" -PercentComplete 40
    $PubIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Location $Location -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4 
    Write-Progress -Activity 'Creating Azure resources' -Status "Creating NSG" -PercentComplete 60
    $NSGRuleRDP = New-AzNetworkSecurityRuleConfig -Name $VM.NSGName  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow 
    $NSG = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $Location -Name $VM.SecurityGroup -SecurityRules $NSGRuleRDP 
    Write-Progress -Activity 'Creating Azure resources' -Status "Creating NIC" -PercentComplete 80
    $NIC = New-AzNetworkInterface -Name $VM.NICName -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PubIp.Id -NetworkSecurityGroupId $NSG.Id 
    $VMConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1 | 
      Set-AzVMOperatingSystem -Windows -ComputerName $VM.Name -Credential $Cred | 
      Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus '2016-Datacenter' -Version latest | 
      Add-AzVMNetworkInterface -Id $NIC.Id
      Write-Progress -Activity 'Creating Azure resources' -Status "Creating VM" -PercentComplete 100 -Completed
    New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VMConfig
  }  
}   