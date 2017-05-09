#! bin/bash
# To get Bugreport, VideoRecording, Screenshot file after running a monkey command on multiple devices
# How to execute:  sh MonkeyRunner_log_collector_1.0.sh <app-packagename> 
# Author : ssirekumar@gmail.com

LOCAL_ADB="adb"
TMP_DIR="fourthMonkey_"$(date|sed -e 's/\ /_/g')
DEVICE_NAMES_WHEN_CRASH="crash_happen_devices.txt"

if [ $# -eq 0 ]; then
 echo "$0 : You must give/supply one parameter"
 exit 1
fi

function display_connected_devices() {
  echo -e "\e[00;33mAndroid devices(s) connected to USB: \e[00m"
  ${LOCAL_ADB} devices
}

function create_local_temp_folder() {
  mkdir $TMP_DIR 
  echo -e "\e[00;34mOutput folder created... Please DO NOT disconnect the device(s) \e[00m"
}

# Waits for user to press Enter
function prepare_user_to_start_capture() {
  echo -e "\e[00;33mIf you're ready to run monkey on above mentioned devices and capture logs, hit Enter. \e[00m"
  echo -e "\e[00;33mElse Hit Ctrl+c to cancel \e[00m"
  read start
}

echo -e "\n\n\e[01;33m>>>>>>>>>>>>>>>>>>>> Monkey Executor and Log Collector Script v1.0 <<<<<<<<<<<<<<<<<<<<<<<<<<<<< \e[00m"
my_array=($(adb devices | sed "1 d" | cut -f 1))
count=0
display_connected_devices
prepare_user_to_start_capture
create_local_temp_folder

for device_serial in "${my_array[@]}"; do
 NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)

 ${LOCAL_ADB} -s $device_serial logcat -c
 ${LOCAL_ADB} -s $device_serial shell screenrecord /sdcard/${NEW_UUID}.mp4 &
 PID=$!  # Get its screenrecord PID
 ${LOCAL_ADB} -s $device_serial shell monkey -p $1 -s 99 -v 10000 --throttle 100 --ignore-timeouts --ignore-security-exceptions --ignore-crashes --ignore-native-crashes --kill-process-after-error

 #If monkey got stoped with any exception or crash it will get recorded in text file
 if [ $(echo $?) != 0 ]; then
    if [ $count > 0 ]; then
     echo -e "\e[01;33m>Message: Crash is Observed on Device ${device_serial} \e[00m"
     echo $(date) ": $device_serial" >> ${DEVICE_NAMES_WHEN_CRASH}
    else
     echo -e "\e[01;33m>Message: Crash is Observed on Device ${device_serial} \e[00m"
     echo $(date) ": $device_serial" > ${DEVICE_NAMES_WHEN_CRASH}
    fi 
 fi 

 echo -e "\e[01;33m>Message:Monkey run has completed on Device ${device_serial} \e[00m"
 mkdir -p $TMP_DIR/$device_serial/ ;
 
 # Bugreport
 echo -e "\e[01;33m>Message:Taking a BugReport from Device ${device_serial} \e[00m"  
 ${LOCAL_ADB} -s $device_serial bugreport > ${TMP_DIR}/${device_serial}/"BugReport_"${device_serial}\_$(date|sed -e 's/\ /_/g').txt
 sleep 3
 
 # ScreenShort
 echo -e "\e[01;33m>Message:Taking a screenshot from Device ${device_serial} \e[00m"  
 ${LOCAL_ADB} -s $device_serial shell screencap -p /sdcard/${NEW_UUID}.png
 ${LOCAL_ADB} -s $device_serial pull /sdcard/${NEW_UUID}.png ${TMP_DIR}/${device_serial}/
 ${LOCAL_ADB} -s $device_serial shell rm /sdcard/${NEW_UUID}.png
 sleep 3

 # ScreenRecord
 kill $PID
 sleep 3
 echo -e "\e[01;33m>Message:Pulling a Screen Record file from Device ${device_serial} \e[00m"
 ${LOCAL_ADB} -s $device_serial pull /sdcard/${NEW_UUID}.mp4 ${TMP_DIR}/${device_serial}/
 ${LOCAL_ADB} -s $device_serial shell rm -f /sdcard/${NEW_UUID}.mp4

 #power off the device 
 ${LOCAL_ADB} -s $device_serial shell input keyevent KEYCODE_POWER

 (( count++ ))
done

echo -e "\e[00;32mMonkey execution has completed"
echo -e "\e[00;32mNow you can copy relevant log files from folder: $TMP_DIR and find the crashes reported on ${DEVICE_NAMES_WHEN_CRASH} \e[00m"





