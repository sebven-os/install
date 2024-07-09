#!/bin/bash


if ! read -t 10 -p "This script will install RagnarOS to your system. Proceed? (y/n): " response; then
	echo "No response received in time. Aborting."
	exit 1
fi

if [[ "$response" =~ ^[Yy]$ ]]; then
	echo "Proceeding..."
else
	echo "Not installing the OS."
	exit 1
fi

GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}! Installing RagnarOS...${NC}"

# Base Packages

echo -e "${GREEN}! Fetching base packages...${NC}"
sudo pacman  -S --noconfirm base-devel git make gcc cmake 

echo -e "${GREEN}! Installing AUR helper...${NC}"
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd ..
rm -rf paru-bin


echo -e "${GREEN}! Settung up Xorg...${NC}"
paru -S --noconfirm xorg xorg-xinit xcb
touch ~/.xinitrc
echo "exec ragnar" > ~/.xinitrc

echo -e "${GREEN}! Installing tools & depdencies...${NC}"
paru -S --noconfirm alacritty vim neovim chromium rofi nitrogen sddm sddm-sugar-dark flameshot libclipboard cglm glfw glu pciutils

echo -e "${GREEN}! Installing tools...${NC}"

echo -e "${GREEN}! Installing the leif framework...${NC}"
git clone https://github.com/cococry/leif
cd leif
git checkout multiple-states
make && sudo make install
cd ..
rm -rf leif

echo -e "${GREEN}! Downloading wallpapers...${NC}"
git clone https://github.com/cococry/wallpapers
sudo mkdir -p /usr/share/ragnar
sudo mv wallpapers /usr/share/ragnar


echo -e "${GREEN}! Settung up Configs...${NC}"

git clone https://github.com/sebven-os/config
cd config
cp -r .config/alacritty ~/.config
sudo cp sddm.conf /etc/
cd ..
rm -rf config

echo -e "${GREEN}! Updating graphics drivers...${NC}"

detect_gpu() {
	if lspci | grep -i nvidia > /dev/null; then
		echo "nvidia"
	elif lspci | grep -i amd > /dev/null; then
		echo "amd"
	elif lspci | grep -i intel > /dev/null; then
		echo "intel"
	else
		echo "unknown"
	fi
}

update_arch() {
	sudo pacman -Syu --noconfirm

	case $1 in
		nvidia)
			sudo pacman -S --noconfirm nvidia nvidia-utils
			;;
		amd)
			sudo pacman -S --noconfirm xf86-video-amdgpu mesa
			;;
		intel)
			sudo pacman -S --noconfirm xf86-video-intel mesa
			;;
		*)
			echo "Unsupported GPU or GPU not detected"
			;;
	esac
}

# Detect the GPU and update the drivers
gpu=$(detect_gpu)
echo -e "${GREEN}! Detected $gpu GPU.${NC}"
update_arch $gpu

echo -e "${GREEN}! Settung up boron...${NC}"
git clone https://github.com/cococry/boron
cd boron
make && sudo make install
cd ..
rm -rf boron

echo -e "${GREEN}! Settung up Ragnar window manager...${NC}"
cd ..
git clone https://github.com/cococry/ragnar
cd ragnar
git checkout ragnaros
make && sudo make install
cd ..

sudo systemctl enable sddm.service

echo -e "${GREEN}! Installation finished!${NC}"
echo -e "${GREEN}! Starting RagnarOS...${NC}"

slepp 2

sudo sddm
