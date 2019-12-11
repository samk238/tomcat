#!/bin/bash
#set -x
#clear
#Modify first few lines to run on any tomact server
export TOMCAT_HOME=$1
export TUSER=$2
export COMMAND=$3

proc() {
PROC=$(ps ux |grep ${TUSER}| grep "org.apache.catalina.startup.Bootstrap"|grep -v grep)
}
tproc() {
export TOTAL_PROC=$(ps ux | grep ${TUSER}|grep "org.apache.catalina.startup.Bootstrap"|grep -v grep | wc -l)
}
pid() {
export PID=$(ps ux | grep ${TUSER}|grep "org.apache.catalina.startup.Bootstrap"|grep -v grep | awk '{print $2}')
}

echo -e "\n###############################################################################"
echo -e "This script can be used to \e[1mVERIFY | START | STOP | RESTART\e[0m ${TUSER} Tomact processes"
echo -e "###############################################################################\n"

if [[ ! -d $TOMCAT_HOME ]]; then echo -e "\nPROVIDED TOMCAT HOME NOT found, please check and re-run with proper inputs....\n\n"; exit 1;fi

verify() {
tproc
if [[ $TOTAL_PROC -eq 1 ]]; then
  echo -e "\nonly ONE tomcat process is running\n"
  proc; echo $PROC
  echo ""
elif [[ $TOTAL_PROC -gt 1 ]]; then
  echo -e "\nmore than ONE tomcat processes are running\n"
  proc; echo $PROC
  echo -e "\n\nPlease check !!!!!!!\n\n"
else
  echo -e "\n$TOTAL_PROC ${TUSER}-Tomcat process are running\nPlease Verify!!!!\n\n\n"
fi
}

stop() {
pid
if [ -z $PID ]; then
  echo -e "\nNO tomcat process RUNNING, please START before SHUTTING DOWN...\n"
  exit 1
else
  cd ${TOMCAT_HOME}/bin
  ./shutdown.sh
  echo -e "\nShutting down, will wait for 20 secs and checks for PID..."
  sleep 20
  tproc
  if [[ $TOTAL_PROC -eq 0 ]]; then
    echo -e "\nShutdown task Completed\n"
  else
    echo -e "\nShutdown NOT succesful with \"shutdown.sh\", killing the PID now..."
      pid
      while [ ! -z $PID ]; do
        kill -9 $PID &>/dev/null
        sleep 5
        pid
        if [[ ! -z $PID ]]; then echo -e "Server isnt down yet..killing again..";fi
      done
      echo -e "\nShutdown task Completed\n"
  fi
fi
}

start() {
pid
if [ ! -z $PID ]; then
  echo -e "\nTomcat process is already RUNNING, please STOP before STARTING...\n"
  exit 1
else
  echo -e "\nStarting Tomcat service now.."
  cd ${TOMCAT_HOME}/bin
  cat /dev/null >| ${TOMCAT_HOME}/logs/catalina.out
  ./startup.sh
  echo -e "Sleeping for 20 secs before starting LOG verfication..."
  sleep 20
  tproc
  if [[ $TOTAL_PROC -eq 1 ]]; then
    echo -e "\nStart intiated Succesfully..\n"
    flag=0
    while [[ $flag -ne 1 ]]; do
      if [[ ! -z $(cat ${TOMCAT_HOME}/logs/catalina.out | grep -i "Server startup") ]]; then flag=1; fi
      echo -e "Server isn't up yet.. waiting for 10sec"
      sleep 10
    done
    echo -e "\n\nServer started Successfully...\n"
    cat ${TOMCAT_HOME}/logs/catalina.out | grep -i "Server startup"
    echo -e "\n"
  else
    echo -e "\nStart intiated failed or more than one process is running, please verify....\n"
    exit 1
  fi
fi
}

if [[ $COMMAND == "VERIFY" ]]; then
  verify
elif [[ $COMMAND == "START" ]]; then
  start
elif [[ $COMMAND == "STOP" ]]; then
  stop
elif [[ $COMMAND == "RESTART" ]]; then
  verify
  echo "######################"
  echo "SHUTTING DONW SERVICES"
  echo "######################"
  stop
  verify
  sleep 5
  echo "####################"
  echo "STARTING UP SERVICES"
  echo "####################"
  start
  verify
  echo -e "\n\nFor logs re-verification:\n\t\"tail -100f ${TOMCAT_HOME}/logs/catalina.out\"\n"
else
  echo ""
  echo -e "\e[1;31mUSAGE:$0 \"TOMACT_HOME\" \"TOMCAT_USER\" \"VERIFY | START | STOP | RESTART\e[0m\""
  echo ""
fi