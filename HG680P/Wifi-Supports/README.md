
# Build Kernel - Support WIFI

## Installation

HG680P - Pantat hitam, menggunakan wireless driver yang berbeda dengan pantat putih. HG680P putih tidak memerlukan update ini, namun dibutuhkan untuk HG680P hitam #8189fs#. 
### Updating to the latest kernel
```bash
  armbian-sync
  armbian-update -k 6.6
```

### Step 2: Install the compilation tools
```bash
    mkdir -p /opt/toolchain
    cd /opt/toolchain
    # Download the compilation tools
    wget https://github.com/ophub/kernel/releases/download/dev/arm-gnu-toolchain-14.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
    # Extract the tools & clean 
    tar -Jxf arm-gnu-toolchain-14.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
    # Install other compilation dependencies (optional; you can manually install missing dependencies based on error messages)
    armbian-kernel -u
```

#### Step 3: Download and compile the driver
```bash
    # Download the driver source code
    cd ~/
    git clone https://github.com/jwrdegoede/rtl8189ES_linux
    cd rtl8189ES_linux
    # Set up the compilation environment
    gun_file="arm-gnu-toolchain-14.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
    toolchain_path="/opt/toolchain"
    toolchain_name="gcc"
    export CROSS_COMPILE="${toolchain_path}/${gun_file//.tar.xz/}/bin/aarch64-none-linux-gnu-"
    export CC="${CROSS_COMPILE}gcc"
    export LD="${CROSS_COMPILE}ld.bfd"
    export ARCH="arm64"
    export M="/root/rtl8189ES_linux"
    export KSRC=/usr/lib/modules/$(uname -r)/build
    # Compile the driver
    make
```

### Step 4: Install the driver
```bash
    sudo cp -f 8189fs.ko /lib/modules/$(uname -r)/kernel/drivers/net/wireless/
    # Update module dependencies
    sudo depmod -a
    # Load the driver module
    sudo modprobe 8189fs
```
### Step 5: Check The Modules
```bash
    # Check if the driver loaded successfully
    lsmod | grep 8189fs
        # Check that the driver loaded successfully
        8189es 1843200 0
        cfg80211 917504 2 8189es,brcmfmac
```