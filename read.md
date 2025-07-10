Hardware Accelerated Codec

Intel(recent)
# Using the rpmfusion-nonfree section

sudo dnf install intel-media-driver

Intel(older)
# Using the rpmfusion-free section

sudo dnf install libva-intel-driver

Hardware codecs with AMD (mesa)
# Using the rpmfusion-free section This is needed since Fedora 37 and later... and mainly concern AMD hardware since NVIDIA hardware with nouveau doesn't work well

sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
If using i686 compat libraries (for steam or alikes):

sudo dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
sudo dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686

Hardware codecs with NVIDIA
The Nvidia proprietary driver doesn't support VAAPI natively, but there is a wrapper that can bridge NVDEC/NVENC with VAAPI

sudo dnf install libva-nvidia-driver
You can also install both 32bit and 64bit flavor in one command as needed.

sudo dnf install libva-nvidia-driver.{i686,x86_64}



Play a DVD
You need to have the libdvdcss package, to install libdvdcss you need enable tainted repos.

Tainted free is dedicated for FLOSS packages where some usages might be restricted in some countries.

sudo dnf install rpmfusion-free-release-tainted
sudo dnf install libdvdcss

Various firmwares
Tainted nonfree is dedicated to non-FLOSS packages without a clear redistribution status by the copyright holder. But is allowed as part of hardware inter-operability between operating systems in some countries :

sudo dnf install rpmfusion-nonfree-release-tainted
sudo dnf --repo=rpmfusion-nonfree-tainted install "*-firmware"
CategoryHowto

Howto/Multimedia (last edited 2024-10-24 21:36:33 by NicolasChauvet)