#Name- Amanpreet Singh
#Student Id- 200542344
#Subject- Linux Assignment 3

#!/bin/bash

# Adding entries to the hosts file
echo "172.16.1.10 loghost" | sudo tee -a /etc/hosts
echo "172.16.1.11 webhost" | sudo tee -a /etc/hosts

# Check if the target1-mgmt hostname is in /etc/hosts
if ! grep -q "target1-mgmt" /etc/hosts; then
    echo "172.16.1.12 target1-mgmt" | sudo tee -a /etc/hosts
fi

# Function to execute SSH commands and handle errors
execute_ssh() {
    ssh_command=$1
    ssh_host=$2

    # Execute SSH command
    output=$(ssh remoteadmin@"$ssh_host" "$ssh_command" 2>&1)

    # Check for errors
    if [ $? -ne 0 ]; then
        echo "Error executing command on $ssh_host: $output"
        exit 1
    fi
}

# Update the hosts file on the NMS to include the target machines
echo "172.16.1.10 loghost" | sudo tee -a /etc/hosts
echo "172.16.1.11 webhost" | sudo tee -a /etc/hosts

# Configure target1-mgmt
execute_ssh "hostnamectl set-hostname loghost" "target1-mgmt"
execute_ssh "sudo sed -i 's/target1/loghost/g' /etc/hosts" "target1-mgmt"
execute_ssh "sudo ifconfig eth0 172.16.1.3 netmask 255.255.255.0" "target1-mgmt"
execute_ssh "sudo ifconfig eth0 up" "target1-mgmt"
execute_ssh "sudo apt-get install ufw -y" "target1-mgmt"
execute_ssh "sudo ufw allow from 172.16.1.0/24 to any port 514 udp" "target1-mgmt"
execute_ssh "sudo sed -i 's/# imudp/imudp/' /etc/rsyslog.conf" "target1-mgmt"
execute_ssh "sudo sed -i 's/# imudp@255.255.255.255:514/imudp@255.255.255.255:514/' /etc/rsyslog.conf" "target1-mgmt"
execute_ssh "sudo systemctl restart rsyslog" "target1-mgmt

# Configure target2-mgmt
execute_ssh "hostnamectl set-hostname webhost" "target2-mgmt"
execute_ssh "sudo sed -i 's/target2/webhost/g' /etc/hosts" "target2-mgmt"
execute_ssh "sudo ifconfig eth0 172.16.1.4 netmask 255.255.255.0" "target2-mgmt"
execute_ssh "sudo ifconfig eth0 up" "target2-mgmt"
execute_ssh "sudo apt-get install ufw -y" "target2-mgmt"
execute_ssh "sudo ufw allow from any to any port 80" "target2-mgmt"
execute_ssh "sudo apt-get install apache2 -y" "target2-mgmt"
echo ". @loghost" | sudo tee -a /etc/rsyslog.conf

# Verify webhost configuration
firefox http://webhost &>/dev/null

# Verify rsyslog configuration on loghost
execute_ssh "grep webhost /var/log/syslog" "loghost"

# Notify user of script completion
echo "Configuration update successful!"
