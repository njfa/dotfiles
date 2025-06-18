if command -v lazydocker >/dev/null 2>&1; then
    LAZYDOCKER_INSTALLED_VERSION=$(lazydocker --version | grep -o 'Version: [^,]*' | awk '{print $2}')
    echo "lazydocker is installed. now version: $LAZYDOCKER_INSTALLED_VERSION"
else
    echo "lazydocker is not installed."
fi

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
