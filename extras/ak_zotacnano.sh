#!/bin/bash

os=$(ls /usr/bin/*session)
if [[ "${os}" =~ "lxsession" ]];
then
    os="lubuntu"
else
    os="ubuntu"
fi;
if test ${os} != "lubuntu";
then
    echo "This script will only work if Lubuntu is installed. You are using ${os}"
    exit
fi;

release=$(lsb_release -sr);

clear
read -n 1 -p "What is the resolution width? [1280]: " x_res
echo ""
read -n 1 -p "What is the resolution height? [720]: " y_res
echo ""
read -n 1 -p "Is this a rotated (portrait) setup? [y/n]: " -t 10 rotated
echo ""
echo "ADS URL examples:"
echo "http://127.0.0.1:88/zbox/zbox_player.htm [default], use for stand-alone (CLOUD) Zotac playiung full-screen movie in a loop"
echo "http://127.0.0.1:88/ads/ads.htm , use for stand-alone (CLOUD) Zotac playing Default_Presentation"
echo "http://10.100.0.1/ads/ads.php , use for Zotac with local ADS server (non-CLOUD)"
echo "http://192.168.1.224/ads/ads.php , use for Zotac with Nick's 224 ADS server (non-CLOUD)"
echo "http://192.168.1.226/ads/ads.php , use for Zotac with Nick's 226 ADS server (non-CLOUD)"
echo "file:///var/www/ADS__STANDALONE_DATA/zbox/zbox_player.htm"
echo ""
read -p "Please enter the ADS URL (if known): " ads_url

if test -z ${x_res};
then
    x_res="1280"
fi
if test -z ${y_res};
then
    y_res="720"
fi
if test -z ${ads_url};
then
    ads_url="http://127.0.0.1:88/zbox/zbox_player.htm"
fi

#read -p "How often in minutes should the browser restart (default: 60): " mins
#if test -z ${mins};
#then
#    mins=60
#fi
#secs=$(echo "${mins}*60" |bc)

clear
echo "Updating Lubuntu Installation (security patches etc)"
echo "This step will take several minutes"
sleep 1
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt-get update
sudo apt-get -qy upgrade
sudo apt-get -qy dist-upgrade
sudo ubuntu-drivers autoinstall
sudo apt-get -qy install unattended-upgrades
echo "Update done"
sleep 3

# Install TeamViewer
clear
read -n 1 -p "Do you want to install TeamViewer? [y/n]: " -t 20 install_teamviewer
if [ ${install_teamviewer} = "y" -o ${install_teamviewer} = "Y" ];
then
    sudo dpkg --add-architecture i386
    sudo apt-get -qy install libjpeg62:i386 libxinerama1:i386 libxrandr2:i386 libxtst6:i386 ca-certificates
    tv_installed=$(which teamviewer)
    if test -z ${tv_installed};
    then
        sudo apt-get -qy update
        sudo apt-get -qy purge teamviewer
        sudo updatedb
        locate teamviewer | xargs /bin/rm -rf
        wget -q http://175.103.28.7/xkloud/zotac/teamviewer_i386.deb
        sudo dpkg -i --force-depends teamviewer_i386.deb
        sudo apt-get -fy install
        echo "TeamViewer installed"
    else
        read -n 1 -p "Teamviewer is already installed. Do you want to re-install it? [y/n]: " -t 10 tv_reinstall
        if test ${tv_reinstall} = "y" -o ${tv_reinstall} = "Y";
        then
            sudo apt-get -qy purge teamviewer
            sudo updatedb
            locate teamviewer | sudo xargs /bin/rm -rf
            wget -q http://175.103.28.7/xkloud/zotac/teamviewer_i386.deb
            sudo dpkg -i --force-depends teamviewer_i386.deb
            sudo apt-get -fy install
            echo "TeamViewer re-installed"
        fi
    fi
fi
sleep 3

clear
echo "Installing extra software (Google Chrome etc)"
sleep 3
check_sources=$(locate google*.list);
if test -z check_sources;
then
    rm -f linux_signing_key.pub
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
fi
sudo apt-get update
sudo apt-get -qy install arandr google-chrome-stable build-essential ca-certificates curl python dconf-tools mesa-utils openssh-server openssl vlc browser-plugin-vlc update-notifier-common gedit mc unclutter

sudo apt-get -qy install
sudo apt-get -y --force-yes upgrade
sudo apt-get -y autoremove
sudo apt-get -q -fy install

clear
echo "Enabling Auto-login"
DateTimeStamp=$(date '+%Y%m%d-%H%M%S');
lightdm_backup="/etc/lightdm/lightdm.conf.${DateTimeStamp}"
sudo cp -p /etc/lightdm/lightdm.conf ${lightdm_backup}
cat << ADSEOF1 > /tmp/lightdm
[Seat:*]
autologin-guest=false
autologin-user=eze_zbox
autologin-user-timeout=0
ADSEOF1

sudo cp /tmp/lightdm /etc/lightdm/lightdm.conf

# Set background colour to black
perl -pi -w -e 's{desktop_bg=.+?$}{desktop_bg=#000000}smx;' ~/.config/pcmanfm/lubuntu/desktop-items-0.conf
pcmanfm --wallpaper-mode=color

echo "Enabling ROOT access for SSH"
sudo restart ssh
DateTimeStamp=$(date '+%Y%m%d-%H%M%S');
sshd_backup="/etc/ssh/sshd_config.${DateTimeStamp}"
sudo cp -p /etc/ssh/sshd_config ${sshd_backup}
sudo sed -i "s/PermitRootLogin without-password/PermitRootLogin yes/" /etc/ssh/sshd_config
sudo service ssh restart

# Disable Error Reporting
sudo sed -i "s/enabled=1/enabled=0/" /etc/default/apport

# Change Ubuntu environment
echo "Tweaking environment"
# Set power button to Shutdown
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/power-button-action -s 4

# Disable screen off timeout
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-off -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-on-ac-sleep -s 0

# Set panel to Auto-Hide
sed -i "/autohide/d" ~/.config/lxpanel/Lubuntu/panels/panel
perl -e 'open my $fh, q{<}, q{panel} or die $!; my $text = do { local ( $/ ); <$fh> }; close $fh; $text =~ s{\}}{  autohide=1\n\}}smx; open $fh, q{>}, q{panel} or die $!; print $fh $text; close $fh;'

# Adding Chrome to Autostart
if grep -Fq "google-chrome-stable" ~/.config/lxsession/Lubuntu/autostart
then
    echo "Removing existing Chrome command from Autostart"
    sed -i "/google-chrome-stable/d" ~/.config/lxsession/Lubuntu/autostart
fi
#if grep -Fq "browser-loop" ~/.config/lxsession/Lubuntu/autostart
#then
#    sed -i "/browser-loop/d" ~/.config/lxsession/Lubuntu/autostart
#fi

echo "Adding Chrome to Autostart"
echo "/usr/bin/google-chrome-stable --kiosk --incognito ${ads_url}" >> ~/.config/lxsession/Lubuntu/autostart

#echo "#!/bin/bash" > /tmp/browser-loop
#echo "while [ 1 = 1 ]; do" >> /tmp/browser-loop
#echo "pkill -f chrome" >> /tmp/browser-loop
#echo "sleep 1" >> /tmp/browser-loop
#echo "/usr/bin/google-chrome-stable --disable-gpu --kiosk --incognito ${ads_url} &" >> /tmp/browser-loop
#echo "sleep ${secs}" >> /tmp/browser-loop
#echo "done" >> /tmp/browser-loop
#
#sudo mv /tmp/browser-loop /opt/browser-loop.sh
#sudo chmod +x /opt/browser-loop.sh
#echo "/opt/browser-loop.sh &" >> ~/.config/lxsession/Lubuntu/autostart

# Restart TeamViewer 2 minutes after boot. TeamViewer gets stuffed up when XRandR is used
cronfile='/etc/cron.d/restart-teamviewer'
tmpfile="${HOME}/restart-teamviewer"
sudo echo "SHELL=/bin/bash" > ${tmpfile}
sudo echo "PATH=${PATH}" >> ${tmpfile}
sudo echo "# Restart teamviewer 2 minutes after boot" >> ${tmpfile}
sudo echo "@reboot root (sleep 120; teamviewer daemon restart) > /dev/null 2>&1 &" >> ${tmpfile}

sudo mv ${tmpfile} ${cronfile}
sudo chmod u=rw,g=r,o=r ${cronfile}
sudo chown root:root ${cronfile}

# Add browser check to cron
wget -q -O ${HOME}/check-browser.sh http://175.103.28.7/xkloud/zotac/check-browser.sh
sudo mv ${HOME}/check-browser.sh /opt/check-browser.sh
chmod +x /opt/check-browser.sh

cronfile='/etc/cron.d/check-browser'
tmpfile="${HOME}/check-browser"
echo "SHELL=/bin/bash" > ${tmpfile}
echo "PATH=${PATH}" >> ${tmpfile}
echo "# Check browser is running every 2 minutes" >> ${tmpfile}
echo "*/2 * * * * ${USER} /opt/check-browser.sh > /dev/null 2>&1 &" >> ${tmpfile}

sudo mv ${tmpfile} ${cronfile}
sudo chmod u=rw,g=r,o=r ${cronfile}
sudo chown root:root ${cronfile}

clear
echo "Setup auto-updates for security patches etc"
#sudo dpkg-reconfigure -plow unattended-upgrades
# Setup auto-updates for security patches etc
sudo echo 'APT::Periodic::Update-Package-Lists "7";' > /etc/apt/apt.conf.d/20auto-upgrades
sudo echo 'APT::Periodic::Unattended-Upgrade "7";' >> /etc/apt/apt.conf.d/20auto-upgrades
sudo echo 'APT::Periodic::AutocleanInterval "7";' >> /etc/apt/apt.conf.d/20auto-upgrades
sudo sed -i "s/Prompt=lts/Prompt=never/" /etc/update-manager/release-upgrades
sudo sed -i "s/\/\/Unattended-Upgrade::Automatic-Reboot \"false\"/Unattended-Upgrade::Automatic-Reboot \"true\"/" /etc/apt/apt.conf.d/50unattended-upgrades
sudo /etc/init.d/unattended-upgrades restart
clear
echo "Auto-login enabled"
echo "TeamViewer, Arandr, Google Chrome, OpenSSH and VLC installation complete"
echo "Power off button configured"
echo "Screen saver function turned off"
echo "Chrome Auto-Startup installed"
echo "Auto update for security patches activated"
echo ""
echo "A reboot is required. Once rebooted, test the system to ensure everything is good to go"
read -p "Press any key to continue..." -n 1 -t 10

# Forcing resolution to be set correctly
hdmi_port=$(xrandr -q | grep HDMI | grep " connected" | cut -d' ' -f1);
if test -z ${hdmi_port};
then
    hdmi_port="HDMI1"
fi
echo '#!/bin/sh' > ~/resolution_fix
echo 'xrandr --newmode "${x_res}x${y_res}_60.00"   74.50  ${x_res} 1344 1472 1664  ${y_res} 723 728 748 -hsync +vsync' >> ~/resolution_fix
echo "xrandr --addmode ${hdmi_port[0]} \"${x_res}x${y_res}_60.00\"" >> ~/resolution_fix
if test ${rotated} = "y" -o ${rotated} = "Y";
then
    echo "xrandr --output ${hdmi_port[0]} --primary --mode \"${x_res}x${y_res}_60.00\" --rotate left" >> ~/resolution_fix
else
    echo "xrandr --output ${hdmi_port[0]} --primary --mode \"${x_res}x${y_res}_60.00\"" >> ~/resolution_fix
fi
chmod +x ~/resolution_fix
sudo mv ~/resolution_fix /opt/resolution_fix.sh
if grep -Fq "resolution_fix" ~/.config/lxsession/Lubuntu/autostart
then
    echo "Removing existing resolution fix from Autostart"
    sed -i "/resolution_fix/d" ~/.config/lxsession/Lubuntu/autostart
fi
echo "/opt/resolution_fix.sh" >> ~/.config/lxsession/Lubuntu/autostart

# Andrew Pain fix
echo "options i915_bdw enable_rc6=0 semaphores=1 fastboot=0 enable_fbc=0 powersave=0" > /tmp/i915.conf
sudo mv /tmp/i915.conf /etc/modprobe.d/i915.conf
sudo update-initramfs -u
sudo mkdir -p /etc/X11/xorg.conf.d
cat << X11FIX > /tmp/20-intel.conf
Section "Extensions"
    Option  "XVideo"    "Disable"
EndSection

Section "Device"
    Identifier  "Intel Graphics"
    Driver      "intel"
    Option      "AccelMethod" "sna"
    Option      "TearFree" "true"
    Option      "DRI" "true"
EndSection
X11FIX

# Start TeamViewer first time to setup
echo "Exit teamviewer when you have finished setting it up"
sudo /usr/bin/teamviewer daemon start &> /dev/null
sudo teamviewer passwd eze_zotac_ss
#/usr/bin/teamviewer &> /dev/null

# Set max_cstate=1 in GRUB
sudo mv /tmp/20-intel.conf /etc/X11/xorg.conf.d/20-intel.conf
cp /etc/default/grub ~/grub.default
sudo sed -i -E "s/GRUB_CMDLINE_LINUX_DEFAULT.+$/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash intel_idle.max_cstate=1\"/" /etc/default/grub
sudo sed -i -E "s/GRUB_TIMEOUT=.+$/GRUB_TIMEOUT=3/" /etc/default/grub
sudo update-grub
echo "Reboot required. Rebooting now..."
sleep 3
sudo reboot
