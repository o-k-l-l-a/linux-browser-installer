#!/bin/bash

# ===============================
# Check Docker Installation
# ===============================
install_docker() {
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh

    if command -v systemctl &> /dev/null; then
        sudo systemctl enable docker || true
        sudo systemctl start docker || true
    fi

    if ! getent group docker > /dev/null 2>&1; then
        sudo groupadd docker
    fi

    sudo usermod -aG docker ${SUDO_USER:-$USER} || true
    echo "Docker installed successfully. Please log out and log back in for group changes to take effect."
}

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed."
    read -p "Press Enter to install Docker..."
    install_docker
else
    echo "Docker is already installed."
fi

# ===============================
# Generic install/uninstall functions
# ===============================
install_browser() {
    local NAME=$1
    local IMAGE=$2
    local PORT=$3

    if docker ps -a | grep -q $NAME; then
        echo "$NAME is already installed."
    else
        read -p "Enter username for $NAME: " USERNAME
        read -sp "Enter password for $NAME: " PASSWORD
        echo

        # Create config directory
        CONFIG_DIR="/opt/browser-config/$NAME"
        sudo mkdir -p "$CONFIG_DIR"
        sudo chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$CONFIG_DIR"

        echo "Installing $NAME..."
        docker run -d \
            --name=$NAME \
            --security-opt seccomp=unconfined \
            -e PUID=$(id -u ${SUDO_USER:-$USER}) \
            -e PGID=$(id -g ${SUDO_USER:-$USER}) \
            -e TZ=Etc/UTC \
            -e CUSTOM_USER=$USERNAME \
            -e PASSWORD=$PASSWORD \
            -p $PORT:3000 \
            -v $CONFIG_DIR:/config \
            --shm-size="1gb" \
            --restart unless-stopped \
            $IMAGE

        echo "------------------------------------------------------------------------------------------------"
        echo "$NAME installed successfully."
        IP=$(hostname -I | awk '{print $1}')
        echo "Use browser with http://$IP:$PORT"
        echo "Note: Using --security-opt seccomp=unconfined may reduce container security."
    fi
}

uninstall_browser() {
    local NAME=$1
    if docker ps -a | grep -q $NAME; then
        echo "Uninstalling $NAME..."
        docker stop $NAME
        docker rm $NAME
        echo "$NAME uninstalled."
    else
        echo "$NAME is not installed."
    fi
}

# ===============================
# Menu (single choice)
# ===============================
echo "Select an option:"
echo "1) Install Chromium"
echo "2) Uninstall Chromium"
echo "3) Install Firefox"
echo "4) Uninstall Firefox"
echo "5) Install Brave"
echo "6) Uninstall Brave"
echo "7) Install Vivaldi"
echo "8) Uninstall Vivaldi"
echo "9) Install Midori"
echo "10) Uninstall Midori"
echo "11) Install Epiphany"
echo "12) Uninstall Epiphany"
echo "13) Exit"

read -p "Please choose: " choice

case $choice in
    1) install_browser "chromium" "lscr.io/linuxserver/chromium:latest" 3000 ;;
    2) uninstall_browser "chromium" ;;
    3) install_browser "firefox" "lscr.io/linuxserver/firefox:latest" 4000 ;;
    4) uninstall_browser "firefox" ;;
    5) install_browser "brave" "lscr.io/linuxserver/brave:latest" 5000 ;;
    6) uninstall_browser "brave" ;;
    7) install_browser "vivaldi" "lscr.io/linuxserver/vivaldi:latest" 6000 ;;
    8) uninstall_browser "vivaldi" ;;
    9) install_browser "midori" "lscr.io/linuxserver/midori:latest" 7000 ;;
    10) uninstall_browser "midori" ;;
    11) install_browser "epiphany" "lscr.io/linuxserver/epiphany:latest" 8000 ;;
    12) uninstall_browser "epiphany" ;;
    13) exit ;;
    *) echo "Invalid choice. Please select a valid option." ;;
esac
