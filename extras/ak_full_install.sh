#!/bin/bash
clear
os=$(ls /usr/bin/*session)
if [[ "${os}" =~ "lxsession" ]];
then
    os="lubuntu"
else
    os="ubuntu"
fi;

echo "Downloading install pack to /tmp directory, from http://175.103.28.7/xcloud/zotac/zotac.install_pack.tar"
sleep 1
cd /tmp
rm -f zotac.install_pack.tar
wget http://175.103.28.7/xcloud/zotac/zotac.install_pack.tar && result="OK" || result="FAIL"
if test ${result} != "OK";
then
    echo "Download of required package zotac.install_pack.tar failed. Check internet connection."
    echo "If problem persists, ask Andrew Kirkland for assistance"
    echo "skype: djandiek"
    echo "email: andrew.kirkland@movielink.net.au"
    exit
fi;
cd -
echo
echo "Extracting downloaded package"
sudo tar -C / -xpvf /tmp/zotac.install_pack.tar
echo
echo "Extraction complete"
sleep 3

clear
case ${os} in
ubuntu)
    label="Ubuntu"
    dir="install_list.trusty-ubuntu.14-04"
;;
lubuntu)
    label="Lubuntu"
    dir="install_list.xenial-lubuntu.16-04"
;;
*)
    echo && echo
    exit
;;
esac
echo
echo "Installing Andrej's ${label} Additions"
sleep 3;
cd /${dir}/
chmod +x /${dir}/001.install.ads_additions.sh
sudo ./001.install.ads_additions.sh

clear
os=$(ls /usr/bin/*session)
if [[ "${os}" =~ "lxsession" ]];
then
    os="lubuntu"
else
    os="ubuntu"
fi;
script=""
case ${os} in
ubuntu)
    script="ak_zotac4port.sh"
;;
lubuntu)
    script="ak_zotacnano.sh"
;;
*)
    echo && echo
    exit
;;
esac

rm -f ak_patch.sh
wget -q -O ak_patch.sh http://175.103.28.7/xkloud/zotac/${script} && result="OK" || result="FAIL"
if test ${result} != "OK";
then
    echo "Download of required script ${script} failed. Check internet connection."
    echo "If problem persists, ask Andrew Kirkland for assistance"
    echo "skype: djandiek"
    echo "email: andrew.kirkland@movielink.net.au"
    exit
fi;
chmod +x ak_patch.sh
./ak_patch.sh
rm ak_patch.sh
pause
