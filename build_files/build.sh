#!/bin/bash

set -ouex pipefail

### Install packages

dnf5 install -y libicu76
dnf5 install -y --releasever=42 webkit2gtk4.0
dnf5 install -y --setopt=tsflags=noscripts /ctx/ps-pulse-linux-22.8r6-b44527-installer.rpm

mkdir -p /var/lib/pulsesecure/pulse
setfacl -d -m g::r /var/lib/pulsesecure/pulse
setfacl -d -m o::r /var/lib/pulsesecure/pulse
systemctl enable /lib/systemd/system/pulsesecure.service
/opt/pulsesecure/bin/setup_cef.sh install

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

dnf install -y fedora-workstation-repositories
dnf config-manager setopt google-chrome.enabled=1

rpm --import https://downloads.1password.com/linux/keys/1password.asc
# sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

sh -c 'echo -e "[1password]\nname=1Password Beta Channel\nbaseurl=https://downloads.1password.com/linux/rpm/beta/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

# this installs a package from fedora repos
dnf5 install -y niri swaylock swaybg swayidle firefox xdg-desktop-portal-gnome xdg-desktop-portal-gtk gnome-keyring alacritty fuzzel polkit-kde xwayland-satellite mako ly chezmoi net-tools google-chrome-stable 1password NetworkManager-tui dolphin

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
