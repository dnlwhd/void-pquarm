#!/bin/sh

pwd=$(dirname "$(realpath "$0")")

source_dir="$pwd"
nvidia_pkg=nvidia
display_mgr=lightdm

export WINEPREFIX="$source_dir"/project-quarm
export WINEARCH=win32

[ "$1" = -u ] && {
    sudo xbps-remove -yR Vulkan-Headers Vulkan-Tools wine wine-32bit winetricks wine-gecko wine-mono
    rm -r "$WINEPREFIX"
    rm "$source_dir"/pq-run.sh /usr/local/bin/pq-run.sh
    exit
}

### Install Nvidia drivers and 32-bit libraries
sudo xbps-install -yS void-repo-nonfree void-repo-multilib-nonfree
sudo xbps-install -yS "$nvidia_pkg" "$nvidia_pkg"-libs-32bit

[ "$?" != 0 ] && {
    sudo xbps-remove -yR void-repo-nonfree void-repo-multilib-nonfree
    exit 1
}
sudo xbps-remove -yR void-repo-nonfree void-repo-multilib-nonfree

### Install curl
sudo xbps-install -yS curl

### Download Client & Dependencies
mkdir -p "$source_dir"

[ -f "$source_dir"/TAKP_PC_V2.1c.zip ] \
|| curl -Lo "$source_dir"/TAKP_PC_V2.1c.zip "https://www.dropbox.com/s/bppy4ebt7vl7hwk/TAKP%20PC%20V2.1c.zip?dl=1"

[ -f "$source_dir"/dgVoodoo2_81_3.zip ] \
|| curl -O http://dege.freeweb.hu/dgVoodoo2/bin/dgVoodoo2_81_3.zip

[ -f "$source_dir"/dxvk-2.3.tar.gz ] \
|| curl -OL https://github.com/doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz

[ -f "$source_dir"/projectquarm_08_05_2023.zip ] \
|| curl -O https://cdn.discordapp.com/attachments/1135981619858128998/1137492344162234368/projectquarm_08_05_2023.zip

### Install Vulkan & WINE
sudo xbps-install -yS void-repo-multilib
sudo xbps-install -yS Vulkan-Headers Vulkan-Tools wine wine-32bit winetricks wine-gecko wine-mono
sudo xbps-remove -yR void-repo-multilib

### Create WINE Prefix
wineboot

### Extract dxvk to the WINE Prefix
tar --wildcards --strip-components=2 -xzf "$source_dir"/dxvk-2.3.tar.gz -C "$WINEPREFIX"/drive_c/windows/system32 dxvk-2.3/x32/*.dll

### Extract the client into WINE Prefix
unzip "$source_dir"/TAKP_PC_V2.1c.zip -d "$WINEPREFIX"

### Extract dgVoodoo into the client
unzip -jo "$source_dir"/dgVoodoo2_81_3.zip MS/x86/D3D8.dll MS/x86/D3D9.dll dgVoodooCpl.exe -d "$WINEPREFIX/TAKP PC V2.1"
mv "$WINEPREFIX/TAKP PC V2.1/D3D8.dll" "$WINEPREFIX/TAKP PC V2.1/d3d8.dll"
mv "$WINEPREFIX/TAKP PC V2.1/D3D9.dll" "$WINEPREFIX/TAKP PC V2.1/d3d9.dll"

### Add DLL Overrides for dxvk and dgVoodoo to the WINE Prefix
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d11 /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d10core /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v dxgi /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d9 /d native /f >/dev/null 2>&1
wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v d3d8 /d native /f >/dev/null 2>&1

### Extract the Project Quarm files into the client
unzip -o "$source_dir"/projectquarm_08_05_2023.zip -d "$WINEPREFIX/TAKP PC V2.1"

### Set ESync Limits
grep "$USER hard nofile 524288" /etc/security/limits.d/"$USER" \
|| echo "$USER hard nofile 524288" | sudo tee /etc/security/limits.d/"$USER" >/dev/null

grep "session required /lib/security/pam_limits.so" /etc/pam.d/login \
|| echo "session required /lib/security/pam_limits.so" | sudo tee -a /etc/pam.d/login >/dev/null

grep "session required /lib/security/pam_limits.so" /etc/pam.d/"$display_mgr" \
|| echo "session required /lib/security/pam_limits.so" | sudo tee -a /etc/pam.d/lightdm >/dev/null

### Create a run script and add it to the $PATH
echo '#!/bin/sh' > "$source_dir"/pq-run.sh
echo "export WINEPREFIX=$source_dir/project-quarm" >> "$source_dir"/pq-run.sh
echo 'cd "$WINEPREFIX/TAKP PC V2.1"' >> "$source_dir"/pq-run.sh
echo 'wine eqgame.exe' >> "$source_dir"/pq-run.sh
chmod +x "$source_dir"/pq-run.sh
sudo ln -s "$source_dir"/pq-run.sh /usr/local/bin
