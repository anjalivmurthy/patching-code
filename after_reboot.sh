#!/bin/bash

#COLOUR SCHEME

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
MAG="\033[1;35m"
NC="\033[0m" #No Color

#Variable Declaration

central_server="172.17.0.10" #Remote server
release_ver=$(cat /etc/redhat-release  | awk  '{print $7}' | awk -F "." '{print $1}')
local_log="/tmp/after_reboot_$(hostname)" #local log file
before_logname="before_reboot_$(hostname)"
line_sep=$(for i in {1..70};do echo -n "-"; done)
remote_log="/patching/log_files/" #Remote log file location for uploading
user_name="root" #Remote user for scp


#Check if log file exists
if [ -f "$local_log" ]
then
        cat /dev/null > ${local_log} && echo -e "${GREEN}Old ${local_log} file has been deleted. New file will be created ${NC}"
else
        echo -e "${BLUE}${local_log} file doesn't exist. New file will be created ${NC}"
fi

if [ -f "/tmp/${before_logname}" ]
then
        cat /dev/null > /tmp/${before_logname} && echo -e "${GREEN}Old /tmp/${before_logname} file has been deleted. New file will be downloaded ${NC}"
else
        echo -e "${BLUE}Old /tmp/${before_logname} file has been deleted. New file will be downloaded ${NC}"
fi

#Download file from remote server

echo -e "${BLUE}Downloading log file from ${central_server}. Please enter password when prompted ${NC}\n" | tee -a $local_log
scp ${user_name}@${central_server}:${remote_log}${before_logname} /tmp/.
if [ $? = 0 ]
then
        echo -e "${GREEN}Old ${before_logname} has been downloaded successfully ${NC}" | tee -a $local_log
else
        echo -e "${RED}Error while downloading old $before_logname from remote server. Please check ${NC}" | tee -a $local_log
        exit 1
fi


#Command execution begins here
#SYSTEM INFORMATION
echo -e "${RED}Running pre-requisite collection script ${NC}"

echo -e "\n${line_sep}" | tee -a $local_log;
echo -e "${MAG}1. SYSTEM INFORMATION ${NC}"| tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log;


echo -e "${BLUE}Collecting users logged in details ${NC}" | tee -a $local_log
/usr/bin/w | tee -a $local_log;
echo -e "\n${line_sep}" | tee -a $local_log;


echo -e "${BLUE}Kernel version ${NC}" | tee -a $local_log
uname -r | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}IPtables/Firewalld status ${NC}" | tee -a $local_log
if [ "$release_ver" = "6" ]
then
        /usr/sbin/service iptables status | tee -a $local_log
        echo -e "\n${line_sep}" | tee -a $local_log;
else
        /usr/bin/systemctl status firewalld | tee -a $local_log
        echo -e "\n${line_sep}" | tee -a $local_log;
fi

echo -e "${BLUE}SELINUX status ${NC}" | tee -a $local_log
/usr/sbin/sestatus | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#MEMORY AND PROCESSOR INFORMATION

echo -e "${MAG}2. MEMORY AND PROCESSOR INFORMATION ${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing memory utilization ${NC}" | tee -a $local_log
/usr/bin/free  -m | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing processing unit count ${NC}" | tee -a $local_log
/usr/bin/nproc  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#FILESYSTEM INFORMATION

echo -e "${BLUE}FILE SYSTEM INFORMATION ${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log


echo -e "${BLUE}Capturing mount points ${NC}" | tee -a $local_log
/usr/bin/df -h | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing /etc/fstab entries ${NC}" | tee -a $local_log
cat /etc/fstab  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing pvs output ${NC}" | tee -a $local_log
/usr/sbin/pvs | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing vgs output ${NC}" | tee -a $local_log
/usr/sbin/vgs | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing lvs output ${NC}" | tee -a $local_log
/usr/sbin/lvs | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#NETWORK INFORMATION

echo -e "${MAG}3. NETWORK INFORMATION ${NC}"| tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log


echo -e "${BLUE}Capturing IP routing table using 'ip' command ${NC}" | tee -a $local_log
/usr/sbin/ip r l | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing IP addresses ${NC}" | tee -a $local_log
/usr/sbin/ip addr list | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing IP information using 'ifconfig' ${NC}" | tee -a $local_log
/usr/sbin/ifconfig -a  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing route information using 'route' command ${NC}" | tee -a $local_log
/usr/sbin/route -n | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing /etc/resolv.conf output ${NC}" | tee -a $local_log
cat /etc/resolv.conf  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing NTP details ${NC}" | tee -a $local_log
ntpq  -p | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#MISCELLANEOUS STEPS

echo -e "${MAG}4. MISCELLANEOUS COMMANDS ${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing Date ${NC}" | tee -a $local_log
/usr/bin/date  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Taking backup of /etc/passwd and /etc/fstab ${NC}" | tee -a $local_log
/usr/bin/cp -fp /etc/passwd  /etc/passwd_$(date '+%d%m%Y')
if [ $? = 0 ]
then
        echo -e "${GREEN}Backup of /etc/passwd successful ${NC}" | tee -a $local_log
else
        echo -e "${RED}Backup of /etc/passwd failed ${NC}" | tee -a $local_log
fi
echo -e "\n${line_sep}" | tee -a $local_log

/usr/bin/cp -fp /etc/fstab  /etc/fstab_$(date '+%d%m%Y')
if [ $? = 0 ]
then
        echo -e "${GREEN}Backup of /etc/fstab successful ${NC}" | tee -a $local_log
else
        echo -e "${RED}Backup of /etc/fstab failed. Please check ${NC}" | tee -a $local_log
fi
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Check Splunk,CTM,Tripwire and HTTP processes ${NC}" |tee -a $local_log
/usr/bin/ps -ef | egrep -i "splunk|ctm|tripwire|http" | grep -v grep| tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Checking DS Agent status ${NC}" | tee -a $local_log
/usr/sbin/service ds_agent status | tee -a $local_log

echo

/usr/bin/rpm -qa | grep -i "ds_agent" | tee -a $local_log
sleep 2; echo
/opt/OV/bin/opcagt -status | tee -a $local_log
sleep 2;echo
java -version  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing ${NC}" |tee -a $local_log
/usr/sbin/multipath –ll  | tee -a $local_log ; echo
powermt display dev=all  | tee -a $local_log ; echo
more /sys/class/fc_host/host?/port_state | tee -a $local_log; echo
more /sys/class/fc_host/host?/port_name  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing ulimit for wasadmin ${NC}" | tee -a $local_log
/usr/bin/su - wasadmin -c "ulimit -a"  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Touching /fastboot file ${NC}" | tee -a $local_log
cd / ; touch fastboot  | tee -a $local_log
echo -e "\n${line_sep}" | tee -a $local_log


echo -e "${MAG}Script execution is completed.Please verify output in $local_log file ${NC}\n"

echo -e "${BLUE}Uploading $local_log to Remote server:${central_server} under path $remote_log. Please enter password when prompted. ${NC}\n" | tee -a $local_log
/usr/bin/scp $local_log $user_name@$central_server:$remote_log
if [ $? = 0 ]
then
        echo -e "${GREEN}Log file has been successfully uploaded to ${central_server} server ${NC}" | tee -a $local_log
else
        echo -e "${RED}Log file upload failed to ${central_server} server. Please check manually ${NC}"| tee -a $local_log
fi
