# Name- Amanpreet Singh
# Student ID- 200530998
# Subject- Linux Assignment 2 (System Modification)

#!/bin/bash

# Check if the IP and hostname entry exists in /etc/hosts
echo "Checking /etc/hosts..."
if ! awk -v ip="192.168.16.21" -v hostname="$(hostname)" '
    $1 == ip && $2 == hostname && $3 == "home.arpa" && $4 == "localdomain" { found = 1; exit }
    END { exit !found }
' /etc/hosts; then
    echo "Change required to /etc/hosts"
    echo "Updating /etc/hosts..."
    # Update /etc/hosts if entry not found
    sudo awk -v ip="192.168.16.21" -v hostname="$(hostname)" '
        { if ($1 == ip) $0 = ip "   " hostname " home.arpa localdomain" }
        1
    ' /etc/hosts | sudo tee /etc/hosts > /dev/null
else
    echo "/etc/hosts is already configured."
fi


# Check installed software
echo "Checking installed software..."
required_software=("openssh-server" "apache2" "squid" "ufw")
missing_software=()

# Check if required software is installed
for software in "${required_software[@]}"; do
    if ! dpkg -l | grep -q "ii  $software "; then
        missing_software+=("$software")
    fi
done

# Install missing software using apt-get command
if [ ${#missing_software[@]} -gt 0 ]; then
    echo "Change required: Install the following software packages:"
    for package in "${missing_software[@]}"; do
        echo "Installing: $package"
        sudo apt-get install -y "$package" || display_error "Failed to install $package"
    done
else
    echo "All required software is already installed."
fi




# Check installed software
echo "Checking installed software..."
required_software=("openssh-server" "apache2" "squid" "ufw")
missing_software=()

# Check if required software is installed
for software in "${required_software[@]}"; do
    # Use dpkg -l and awk to check if the required package is installed
    if ! dpkg -l | awk -v pkg="$software" '$2 == pkg && $1 == "ii" { found = 1; exit } END { exit !found }'; then
        missing_software+=("$software") # Add missing software to the list
    fi
done

# Install missing software using apt-get command
if [ ${#missing_software[@]} -gt 0 ]; then
    echo "Change required: Install the following software packages:"
    for package in "${missing_software[@]}"; do
        echo "Installing: $package"
        sudo apt-get install -y "$package" || display_error "Failed to install $package"
    done
else
    echo "All required software is already installed."
fi


# Check SSH configuration
echo "Checking SSH configuration..."

# Use awk to check if 'PasswordAuthentication yes' is configured in /etc/ssh/sshd_config
if ! awk '/^PasswordAuthentication\s+yes$/' /etc/ssh/sshd_config; then
    echo "Change required: Set 'PasswordAuthentication yes' in /etc/ssh/sshd_config"
# Use awk to update 'PasswordAuthentication' line in sshd_config
    sudo awk '/^#?PasswordAuthentication/ {$2="yes"} 1' /etc/ssh/sshd_config | sudo tee /etc/ssh/sshd_config > /dev/null
    # Restart SSH service
    sudo service ssh restart || display_error "Failed to restart SSH service"
else
    echo "SSH configuration is already set to 'PasswordAuthentication yes.'"
fi


# Check Apache configuration
echo "Checking Apache configuration..."
# Use apachectl to check if the SSL module is enabled
if ! apachectl -t -D DUMP_MODULES | awk '/ssl_module/ { found = 1; exit } END { exit !found }'; then
    echo "Change required: Enable the SSL module in Apache"
    sudo a2enmod ssl  # Enable SSL module
    sudo systemctl restart apache2 || display_error "Failed to restart Apache service"
else
    echo "SSL module is already enabled in Apache."
fi


# Check Squid configuration
echo "Checking Squid configuration..."
# Use awk to check if 'http_access allow localnet' is configured in /etc/squid/squid.conf
if ! awk '/^http_access\s+allow localnet$/' /etc/squid/squid.conf; then
    echo "Change required: Add 'http_access allow localnet' to /etc/squid/squid.conf"
    echo "http_access allow localnet" | sudo tee -a /etc/squid/squid.conf > /dev/null  # Add 'http_access allow localnet' to Squid configuration
    sudo service squid restart || display_error "Failed to restart Squid service"
else
    echo "Squid configuration already allows 'localnet' access."
fi


# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    display_error "UFW is not installed on this system."
fi

# Check if UFW is active
if ! sudo ufw status | grep -q "Status: active"; then
echo "Enabling UFW..."
    sudo ufw enable
fi

# Check and add SSH rule (port 22)
if ! sudo ufw status | awk '/22.*ALLOW.*Anywhere/ { found = 1; exit } END { exit !found }'; then
    echo "Change required: SSH (port 22)"
    sudo ufw allow 22
    echo "SSH (port 22) rule added."
else
    echo "SSH (port 22) rule already exists."
fi

# Check and add HTTP rule (port 80)
if ! sudo ufw status | awk '/80.*ALLOW.*Anywhere/ { found = 1; exit } END { exit !found }'; then
    echo "Change required: HTTP (port 80)"
    sudo ufw allow 80
    echo "HTTP (port 80) rule added."
else
    echo "HTTP (port 80) rule already exists."
fi

# Check and add HTTPS rule (port 443)
if ! sudo ufw status | awk '/443.*ALLOW.*Anywhere/ { found = 1; exit } END { exit !found }'; then
    echo "Change required: HTTPS (port 443)"
    sudo ufw allow 443
    echo "HTTPS (port 443) rule added."
else
    echo "HTTPS (port 443) rule already exists."
fi

# Check and add web proxy rule (port 3128)
if ! sudo ufw status | awk '/3128.*ALLOW.*Anywhere/ { found = 1; exit } END { exit !found }'; then
    echo "Change required: Web Proxy (port 3128)"
    sudo ufw allow 3128
    echo "Web Proxy (port 3128) rule added."
else
    echo "Web Proxy (port 3128) rule already exists."
fi

# Define a list of users
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

# Loop through the user list
for user in "${users[@]}"; do
    # Check if the user exists
    if id "$user" &>/dev/null; then
        echo "User '$user' already exists. Skipping creation."
    else
        # Create user with home directory and bash as default shell
        sudo useradd -m -s /bin/bash "$user" || display_error "Failed to create user '$user'"

        # Create .ssh directory and authorized_keys file for SSH keys
        sudo -u "$user" mkdir -p /home/"$user"/.ssh
        sudo -u "$user" touch /home/"$user"/.ssh/authorized_keys
        sudo -u "$user" chmod 700 /home/"$user"/.ssh
        sudo -u "$user" chmod 600 /home/"$user"/.ssh/authorized_keys

        # Add SSH keys for rsa and ed25519 algorithms
        sudo -u "$user" bash -c 'echo "ssh-rsa [RSA_PUBLIC_KEY]" >> ~/.ssh/authorized_keys'
        sudo -u "$user" bash -c 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> ~/.ssh/authorized_keys'

        # Add specific keys for 'dennis' with sudo access
        if [ "$user" = "dennis" ]; then
            # Give 'dennis' sudo access
            sudo usermod -aG sudo "$user" && echo "User '$user' has sudo access."
        fi

        echo "User '$user' created with SSH keys."
    fi
done

echo "User accounts and SSH keys configured successfully."

sudoers_file="/etc/sudoers.d/dennis_nopasswd"

# Check if the sudoers file for 'dennis' exists
if ! awk -v user="dennis" '$0 ~ "^" user "[[:space:]]+ALL" { found = 1; exit } END { exit !found }' "$sudoers_file" &>/dev/null; then
    echo "Change required: Allow 'dennis' to use sudo without a password"
    echo "dennis ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "$sudoers_file" &>/dev/null
else
    echo "Sudo access for 'dennis' is already configured."
fi

echo "Script completed successfully."
