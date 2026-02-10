#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
#Defining logs files to save the output
LOGS_FOLDER="/var/log/roboshops-logs" 
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #We are cutting .sh from the script name(14-logs.sh)
LOG_File=$LOGS_FOLDER/$SCRIPT_NAME.log
mkdir -p $LOGS_FOLDER
echo "your script is running at $(date)" | tee -a $LOG_File
#Defining script to know whether user is a root user or not
if [ $USERID -ne 0 ]
then
echo -e "$R Error: You should be root user to install programme $N" | tee -a $LOG_File
else
echo -e "$G you are running as root user" | tee -a $LOG_File
fi
#Defining function to check whether programme was installed successfully or not
VALIDATE(){
    if [ $1 -eq 0 ]
    then
    echo -e " $G $2 was successful" $N | tee -a $LOG_File
    else
    echo -e "$R $2 was failure"  $N| tee -a $LOG_File
    exit 1
    fi
}

cp mongo.repo /etc/yumrepos.d/mongodb.repo
VALIDATE $? "Copying repos file to /etc/yum.repos.d/mongo.repo

dnf install mongodb-org -y  &>>$LOG_File
VALIDATE $? "Installing mongodb"

systemctl enable mongod  &>>$LOG_File
VALIDATE $? "Mongodb system was enabled"
systemctl start mongod &>>$LOG_File
VALIDATE $? "Mongodb system was started"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"



