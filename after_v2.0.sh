#!/bin/bash

#COLOUR SCHEME

RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
MAG="\033[1;35m"
BROWN="\033[1;33m"
NC="\033[0m" #No Color

#Variable Declaration

central_server="172.17.0.10" #Remote server
release_ver=$(cat /etc/redhat-release  | awk  '{print $7}' | awk -F "." '{print $1}')
local_log="/tmp/after_reboot_$(hostname)_$(date +%d-%m-%y)" #local log file
before_logname="before_reboot_$(hostname)_$(date +%d-%m-%y)"
before_reboot_log="/tmp/${before_logname}"
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

#if [ -f "${before_reboot_log}" ]
#then
#       cat /dev/null > ${before_reboot_log} && eche -e "${GREEN}Old ${before_reboot_log} file has been deleted. New file will be downloaded ${NC}"
#else
#       echo -e "${BLUE}Old /${before_reboot_log} file has been deleted. New file will be downloaded ${NC}"
#fi

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
/usr/bin/w 1>> $local_log;
echo -e "\n${line_sep}" | tee -a $local_log;


echo -e "${BLUE}Kernel version ${NC}" | tee -a $local_log
kernel_ver=$(uname -r)
echo -e "kernel_ver:$kernel_ver " 1>> $local_log
#prev_op=$(cat ${before_reboot_log} | grep -i "kernel_ver" | awk -F ":" '{print $2}')
if [ "$kernel_ver" = $(cat ${before_reboot_log} | grep -i "kernel_ver" | awk -F ":" '{print $2}') ]
then
        kernel_status="${GREEN}Good.$kernel_ver${NC}"
else
        kernel_status="${RED}Mismatch.Current kernel:$kernel_ver. Prev Kernel: $prev_op${NC}"
fi

echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}IPtables/Firewalld status ${NC}" | tee -a $local_log
if [ "$release_ver" = "6" ]
then
        iptable_op=$(/usr/sbin/service iptables status)
	echo -e "IPtable status:$iptable_op" 1>> $local_log
	prev_op=$(cat ${before_reboot_log} | grep -i "iptable_op" | awk -F ":" '{print $2}')
        if [ "$iptable_op" = "$prev_op" ]
        then
                iptable_status="${GREEN}Good${NC}"
        else
                iptable_status="${RED}Mismatch${NC}"
        fi

        echo -e "\n${line_sep}" | tee -a $local_log;
else
        firewall_op=$(/usr/bin/systemctl status firewalld)
        firewall_state=$(/usr/bin/systemctl status firewalld | awk '/Active:/ {print $2 $3}')
        echo -e "Firewall status:$firewall_op" 1>> $local_log
	echo -e "Firewall state:$firewall_state" 1>> $local_log
	prev_state=$(cat ${before_reboot_log} | grep -i "Firewall state" | awk -F ":" '{print $2}')
        if [ "$firewall_state" = "$prev_state" ]
        then
                firewall_status="${GREEN}$firewall_state${NC}"
        else
                firewall_status="${RED}State is $firewall_state. Previously was in $prev_state state ${NC}"
        fi
        echo -e "\n${line_sep}" | tee -a $local_log;
fi

echo -e "${BLUE}SELINUX status ${NC}" | tee -a $local_log
selinux_op=$(/usr/sbin/sestatus)
echo -e "$selinux_op" 1>> $local_log
prev_op=$(cat ${before_reboot_log} | grep -i "SELinux status:" )
if [ "$selinux_op" = "$prev_op" ]
then
        SELinux_status="${GREEN}Good${NC}"
else
        SELinux_status="${RED}Mismatch${NC}"
fi

echo -e "\n${line_sep}" | tee -a $local_log

#MEMORY AND PROCESSOR INFORMATION

echo -e "${MAG}2. MEMORY AND PROCESSOR INFORMATION ${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing memory utilization ${NC}" | tee -a $local_log
mem_op=$(/usr/bin/free  -m)
echo -e "Memory status:$mem_op" 1>> $local_log
free_mem=$(cat ${before_reboot_log} | grep -i -A3 "Memory status" | awk '{print $4}'| head -2 |tail -1)
mem_status="${BLUE}${free_mem} MB is free"


echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing processing unit count ${NC}" | tee -a $local_log
nproc_op=$(/usr/bin/nproc)
echo -e "nproc status:${nproc_op}" 1>> $local_log
if [ "$nproc_op" = $(cat ${before_reboot_log} | grep -i "nproc status" | awk -F ":" '{print $2}') ]
then
        nproc_status="${GREEN}Good${NC}"
else
        nproc_status="${RED}Mismatch${NC}"
fi

echo -e "\n${line_sep}" | tee -a $local_log

#FILESYSTEM INFORMATION

echo -e "${BLUE}FILE SYSTEM INFORMATION ${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log


echo -e "${BLUE}Capturing mount points ${NC}" | tee -a $local_log
df_op=$(/usr/bin/df -h | grep -v "Size")
df_count=$(/usr/bin/df -h | grep -v "Size" | wc -l)
echo -e "df status:\n$df_op" 1>> $local_log
echo -e "df count:$df_count" 1>> $local_log
prev_op=$(cat ${before_reboot_log} | grep -i -A${df_count} "df status"| grep -v "df status")
if [ "$df_op" = "$prev_op" ]
then
        df_status="${GREEN}Good${NC}"
else
	df_status="${RED}Mismatch${NC}"
fi

echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing /etc/fstab entries ${NC}" | tee -a $local_log
fstab_op=$(cat /etc/fstab | grep -v "^$")
fstab_count=$(cat /etc/fstab| grep -v "^$"|wc -l)
echo -e "fstab status:\n$fstab_op"  1>> $local_log
echo -e "fstab entry count:$fstab_count" 1>> $local_log
prev_op=$(cat ${before_reboot_log} | grep -i -A${fstab_count} "fstab status"| egrep -v "fstab status|fstab entry count")
if [ "$fstab_op" = "$prev_op" ]
then
        fstab_status="${GREEN}Good${NC}"
else
        fstab_status="${RED}Mismatch${NC}"
fi

echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing pvs output ${NC}" | tee -a $local_log
pvs_op=$(/usr/sbin/pvs)
echo -e "pv status:$pvs_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing vgs output ${NC}" | tee -a $local_log
vgs_op=$(/usr/sbin/vgs)
echo -e "vg status:$vgs_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing lvs output ${NC}" | tee -a $local_log
lvs_op=$(/usr/sbin/lvs)
echo -e "lv status:$lvs_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#NETWORK INFORMATION

echo -e "${MAG}3. NETWORK INFORMATION ${NC}"| tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log


echo -e "${BLUE}Capturing IP routing table using 'ip' command ${NC}" | tee -a $local_log
ip_op=$(/usr/sbin/ip r l)
echo -e "IP route status:$ip_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing IP addresses ${NC}" | tee -a $local_log
ipa_op=$(/usr/sbin/ip addr list)
echo -e "IP addr status:$ipa_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing IP information using 'ifconfig' ${NC}" | tee -a $local_log
ifcon_op=$(/usr/sbin/ifconfig -a)
echo -e "ifconfig status:$ifcon_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing route information using 'route' command ${NC}" | tee -a $local_log
route_op=$(/usr/sbin/route -n)
echo -e "Route status:$route_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing /etc/resolv.conf output ${NC}" | tee -a $local_log
resolv_op=$(cat /etc/resolv.conf)
echo -e "Resolv status:$resolv_op"  1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing NTP details ${NC}" | tee -a $local_log
ntpq_op=$(/usr/sbin/ntpq  -p); 
echo -e "NTPQ status:$ntpq_op" 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#MISCELLANEOUS STEPS

echo -e "${MAG}4. MISCELLANEOUS COMMANDS ${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing Date ${NC}" | tee -a $local_log
date_op=$(/usr/bin/date)
echo -e "Date status:$date_op"  1>> $local_log
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
splunk_op=$(/usr/bin/ps -ef | egrep -i "splunk" | grep -v grep)
echo -e "Splunk status:$splunk_op" | tee -a $local_log; echo

ctm_op=$(/usr/bin/ps -ef | egrep -i  "ctm" | grep -v grep)
echo -e "CTM status:$ctm_op" | tee -a $local_log ; echo

tpwire_op=$(/usr/bin/ps -ef | egrep -i "tripwire" | grep -v grep)
echo -e "Tripwire status:$tpwire_op" | tee -a $local_log

http_op=$(/usr/bin/ps -ef | egrep -i "http" | grep -v grep)
echo -e "HTTP status:$http_op" | tee -a $local_log

echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Checking DS Agent status ${NC}" | tee -a $local_log
dsagent_op=$(/usr/sbin/service ds_agent status)
echo -e "dsagent status:$dsagent_op" 1>> $local_log ; echo

ds_rpm_op=$(/usr/bin/rpm -qa | grep -i "ds_agent")
echo -e "DSAgent rpm status:$ds_rpm_op" 1>> $local_log
sleep 2; echo

opcagt_op=$(/opt/OV/bin/opcagt -status)
echo -e "OPCAGT status:$opcagt_op" 1>> $local_log
sleep 2;echo

echo -e "${BLUE}Capturing java version${NC}" | tee -a $local_log
java_op=$(java -version)
echo -e "Java version:$java_op"  1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing multipath output ${NC}" |tee -a $local_log
/usr/sbin/multipath –ll  1>>  $local_log ; echo

echo -e "${BLUE}Capturing powermt output ${NC}" | tee -a $local_log
powermt display dev=all  1>> $local_log ; echo

echo -e "${BLUE}Capturing HBA details ${NC}" | tee -a $local_log
more /sys/class/fc_host/host?/port_state 1>> $local_log; echo
more /sys/class/fc_host/host?/port_name 1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Capturing ulimit for wasadmin ${NC}" | tee -a $local_log
/usr/bin/su - wasadmin -c "ulimit -a"  1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

echo -e "${BLUE}Touching /fastboot file ${NC}" | tee -a $local_log
cd / ; touch fastboot  1>> $local_log
echo -e "\n${line_sep}" | tee -a $local_log

#TABLE VIEW OF STATUS
echo -e "${MAG}Sl.No \t Parameter \t\t\t\t Status${NC}" | tee -a $local_log
echo -e "${line_sep}" | tee -a $local_log

echo -e "${MAG}1.\t Kernel Version${NC} \t\t\t $kernel_status" | tee -a $local_log
echo -e "${MAG}2.\t IPtable/Firewalld${NC} \t\t\t $(if [ "${release_ver}" = "6" ]; then echo ${iptable_status};else echo ${firewall_status}; fi)" | tee -a $local_log
echo -e "${MAG}3.\t SELinux Status${NC} \t\t\t $SELinux_status" | tee -a $local_log
echo -e "${MAG}4.\t Memory Status${NC} \t\t\t\t $mem_status" | tee -a $local_log
echo -e "${MAG}5.\t nproc count${NC} \t\t\t\t $nproc_status" | tee -a $local_log
echo -e "${MAG}6.\t Filesystem status${NC} \t\t\t $df_status" | tee -a $local_log
echo -e "${MAG}7.\t /etc/fstab status${NC} \t\t\t $fstab_status" | tee -a $local_log

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

