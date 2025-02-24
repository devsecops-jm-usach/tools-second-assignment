#!/bin/bash
# Remove previous versions
# rm -rf /opt/brokenauthdemo/*
#!/bin/bash

# Update the package manager
echo "sudo yum update -y"
sudo yum update -y

# Install the .NET 8.0 runtime
# Add the Microsoft package signing key
echo "sudo yum install -y libunwind libicu"
sudo yum install -y libunwind libicu

#echo "sudo rpm"
#sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
#echo "sudo sh"
#sudo sh -c 'echo -e "[packages-microsoft-com-prod]\nname=packages-microsoft-com-prod \nbaseurl=https://packages.microsoft.com/yumrepos/microsoft-rhel8.3-prod\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/dotnetdev.repo'

# Install the .NET 8.0 runtime
#echo "sudo yum install -y dotnet-sdk-8.0"
#sudo yum install -y dotnet-sdk-8.0

# Verify the installation
echo "dotnet --"
dotnet --version