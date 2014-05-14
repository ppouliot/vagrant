#!/bin/bash

# We start here
HOME=/home/vagrant
# Get latest stable linux kernel
LATEST_STABLE_KERNEL_URL=http://www.kernel.org$(wget -O - https://www.kernel.org 2>/dev/null | grep -A 5 "Latest Stable Kernel" | awk -F '[""]' '/\.xz/ { print $2 }')
KERNEL=$(echo $LATEST_STABLE_KERNEL_URL | sed 's/.*\///;s/\.tar.*$//')

# Install dependencies


sudo apt-get update

sudo apt-get -y install git language-pack-en libreadline-dev

# Netsniff-NG
sudo apt-get -y install language-pack-en git ccache flex bison libnl-3-dev \
  libnl-genl-3-dev libgeoip-dev libnetfilter-conntrack-dev \
  libncurses5-dev liburcu-dev libnacl-dev libpcap-dev \
  zlib1g-dev libcli-dev libnet1-dev

# Perf tools
apt-get install libaudit-dev libunwind7-dev libelf-dev libgtk2.0-dev \
	libnuma-dev libslang2-dev libdw-dev binutils-dev asciidoc xmlto

# Compile latest Netsniff-NG
git clone http://github.com/netsniff-ng/netsniff-ng
cd netsniff-ng
./configure
sudo mkdir -p /usr/local/share/man/man8/
make && sudo make install

cd $HOME

# Download other useful testing tools
git clone http://github.com/jonschipp/gencfg
git clone https://github.com/netoptimizer/network-testing

# Download, compile, and install latest stable kernel
wget --progress=dot:mega -O - $LATEST_STABLE_KERNEL_URL | tar -xJ
cd $KERNEL
#mv config $KERNEL/.config
make config
make -j 3
make -j 3 modules
sudo make modules_install
sudo make install

# Compile and install bpf debugging programs
cd $KERNEL/tools/net
sudo make bpf_asm
sudo make bpf_dbg
sudo make install

# Compile and install perf tools
#cd linux-3.12.4/tools/perf
#make
#make install
#ln -s /root/bin/perf /usr/sbin/perf

# System and network configuration
sudo mv $HOME/nlmon.cfg /etc/network/interfaces.d/nlmon.cfg
#sudo mv $HOME/dummy.cfg /etc/network/interfaces.d/dummy.cfg
sudo sh -c 'echo "options dummy numdummies=2" > /etc/modprobe.d/local'
cat > /etc/sysctl.d/10-bpf.conf <<EOF
# Enable BPF JIT Compiler (approx. 50ns speed up)
net.core.bpf_jit_enable = 2
EOF

echo "Everything ran! Time for a reboot"
sudo reboot

# Install Linux kernel bpf compiler, disassembler, and debugger