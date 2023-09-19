# PROJECT QUARM ON VOID LINUX

I run Void Linux and wanted to play on Project Quarm.  This guide is for Nvidia cards only, using Vulkan and WINE.

You will need sudo.

# NVIDIA DRIVERS AND LIBRARIES

If you don't have them already, the proprietary Nvidia drivers and 32-bit libraries need to be installed.  Go [here](https://docs.voidlinux.org/config/graphical-session/graphics-drivers/nvidia.html#nvidia-proprietary-driver) and familiarze yourself with the different driver packages, and ensure you install the right ones for your graphics card from the below list.

My GPU is a Nvidia 2070 Super which uses the current / non-legacy drivers and libraries.  I do not know for sure if this works with older cards and their drivers and libraries as they need to support Vulkan and I am not able to test this myself.  The installation commands are provided as a helper in case you have an older card and want to try it out.  **I make no guarantees.**

Additionally, AMD and Intel cards will require entirely different drivers and libraries installed and this process **definitely will not work with them.**

```shell
### Enable nonfree and multilib nonfree repositories
sudo xbps-install -yS void-repo-nonfree void-repo-multilib-nonfree

### nvidia - Series 800+ (current / non-legacy cards)
sudo xbps-install -yS nvidia nvidia-libs-32bit

### nvidia470 - Series 600/700
sudo xbps-install -yS nvidia470 nvidia470-libs-32bit

### nvidia390 - Series 400/500
sudo xbps-install -yS nvidia390 nvidia390-libs-32bit

### Optional: Disable nonfree and multilib nonfree repositories
sudo xbps-remove -yR void-repo-nonfree void-repo-multilib-nonfree
```

# DOWNLOAD CLIENT & DEPENDENCIES

Change the source_dir if you want to install it somewhere else.  A folder 'project-quarm' will be created here to contain the WINE prefix and TAKP client files.  I have only tested this with the listed versions.

If any of the curl commands do not work, go to the commented urls and get the files manually.

```shell
### Source directory
source_dir=/home/$USER/.local/lib/eq
mkdir -p "$source_dir"

### Install curl
sudo xbps-install -yS curl

### TAKP Client 2.1 from https://wiki.takp.info/index.php/Getting_Started_on_Windows
curl -Lo "$source_dir"/TAKP_PC_V2.1c.zip "https://www.dropbox.com/s/bppy4ebt7vl7hwk/TAKP%20PC%20V2.1c.zip?dl=1"

### dgVoodoo 2.81.3 from http://dege.freeweb.hu/dgVoodoo2/dgVoodoo2/
curl -O http://dege.freeweb.hu/dgVoodoo2/bin/dgVoodoo2_81_3.zip

### dxvk 2.3 from https://github.com/doitsujin/dxvk/releases
curl -OL https://github.com/doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz

### Project Quarm server files 08/05/2023 from Project Quarm Discord #server-files
curl -O https://cdn.discordapp.com/attachments/1135981619858128998/1137492344162234368/projectquarm_08_05_2023.zip
```

# INSTALL

```shell
### Enable multilib repository
sudo xbps-install -yS void-repo-multilib

### Install Vulkan & WINE
sudo xbps-install -yS Vulkan-Headers Vulkan-Tools wine wine-32bit winetricks wine-gecko wine-mono

### Optional: Disable multilib repository
sudo xbps-remove -yR void-repo-multilib

### Create the WINE prefix
export WINEPREFIX="$source_dir"/project-quarm
export WINEARCH=win32
wineboot

### Extract dxvk to the WINE prefix
tar --wildcards --strip-components=2 -xzf "$source_dir"/dxvk-2.3.tar.gz -C "$WINEPREFIX"/drive_c/windows/system32 dxvk-2.3/x32/*.dll

### Extract the client into the WINE prefix
unzip "$source_dir/TAKP_PC_V2.1c.zip" -d "$WINEPREFIX"

### Extract dgVoodoo into the client
unzip -jo "$source_dir"/dgVoodoo2_81_3.zip MS/x86/D3D8.dll MS/x86/D3D9.dll dgVoodooCpl.exe -d "$WINEPREFIX/TAKP PC V2.1"
mv "$WINEPREFIX/TAKP PC V2.1/D3D8.dll" "$WINEPREFIX/TAKP PC V2.1/d3d8.dll"
mv "$WINEPREFIX/TAKP PC V2.1/D3D9.dll" "$WINEPREFIX/TAKP PC V2.1/d3d9.dll"

### Add DLL Overrides for dxvk and dgVoodoo
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d11 /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d10core /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v dxgi /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d9 /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d8 /d native /f >/dev/null 2>&1

### Extract the Project Quarm files into the client
unzip -o "$source_dir"/projectquarm_08_05_2023.zip -d "$WINEPREFIX/TAKP PC V2.1"
```

# Set ESync Limits

By default Void has a limit of 4096 concurrent file descriptors which isn't enough to run EQ.  You can check what the current limit is set to with:
```shell
ulimit -Hn
```
If it is set default or some other lowish number, you can add these configurations and reboot to increase it for your user.

* Replace lightdm with whatever display manager you use.
```shell
echo "$USER hard nofile 524288" | sudo tee /etc/security/limits.d/$USER
echo "session required /lib/security/pam_limits.so" | sudo tee -a /etc/pam.d/login
echo "session required /lib/security/pam_limits.so" | sudo tee -a /etc/pam.d/lightdm
```

# RUN

To run the game you must set the WINEPREFIX and launch it from the client directory.  Don't forget to change the source_dir if you changed it earlier.
```shell
export WINEPREFIX="/home/$USER/.local/lib/eq/project-quarm"
cd "$WINEPREFIX/TAKP PC V2.1"
wine eqgame.exe
```

# SCRIPTS

I have scripted this setup for myself in [pq-setup.sh](pq-setup.sh).  By default it will use the directory its in as the source_dir.  It will create `pq-run.sh` in the source_dir and link it in the $PATH (/usr/local/bin) that can be used to start the client.  
`pq-setup.sh -u` will reverse all changes besides the driver and library installations.  
**You may use these at your own risk.**

# UNVERIFIED DEPENDENCIES
These possibly relevant packages are present on my system but I did not specifically install them myself. They may have come down as a dependency of something else as I was testing this.
If the above process isn't working, you can try adding them.

* vulkan-loader
* vulkan-loader-32bit
* libepoxy

# TROUBLESHOOTING

* If you get an error about EQMain.dll not found, make sure you are running the client from its working directory with WINEPREFIX set correctly.

* Test if Vulkan is installed correctly and working.  It should output information about your system and graphics card.  If you get anything else, you might not have rebooted since it was installed, reboot.  If its still not working, you might need to run through the full installation again.
```shell
vulkaninfo
```

* Check if DLLs are properly overriden in the WINE prefix.  Run the command to open regedit in the WINE prefix and navigate to HKEY_CURRENT_USER\Software\Wine\DllOverrides.  Check if d3d11, d3d10core, dxgi, d3d9 and d3d8 are set to 'native'.
```shell
WINEPREFIX=/home/$USER/.local/lib/eq/project-quarm wine regedit
```

# REFERENCES
I pulled this together from these resources.  They may be helpful if you run into issues.

* [ahungry eq-quarm Arch guide](https://gist.github.com/ahungry/b6427ebe04dc6dfbfb0e2122bad0cdab)
* [DXVK Git](https://github.com/doitsujin/dxvk)
* [TAKP Getting Started on Linux](http://wiki.takp.info/index.php?title=Getting_Started_on_Linux)
* [TAKP Getting Started on Linux v3 Wine-Staging 6.0, vulkan & dxvk](https://wiki.takp.info/index.php/Getting_Started_on_Linux_(v3)_Wine-Staging_6.0,_vulkan_%26_dxvk)

# KNOWN PROBLEMS

* Mouse look is a bit janky, often does not register switching directions while right-click is held down.  Happens in first and third person views.  Might get fixed when the Project Quarm devs update the eqgame.dll.
