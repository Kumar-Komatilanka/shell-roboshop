USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
#Defining logs files to save the output
LOGS_FOLDER="/var/log/roboshops-logs" 
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) #We are cutting .sh from the script name(14-logs.sh)
LOG_File=$LOGS_FOLDER/$SCRIPT_NAME.log
SCRIPT_DIR=$(pwd)
mkdir -p $LOGS_FOLDER
echo "your script is running at $(date)" | tee -a $LOG_File
#Defining script to know whether user is a root user or not
if [ $USERID -ne 0 ]
then
echo -e "$R Error: You should be root user to install programme $N" | tee -a $LOG_File
exit 1
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

dnf module disable nginx -y &>>$LOG_File
VALIDATE $? "Disabling Default Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_File
VALIDATE $? "Enabling Nginx:1.24"

dnf install nginx -y &>>$LOG_File
VALIDATE $? "Installing Nginx"

systemctl enable nginx  &>>$LOG_File
systemctl start nginx 
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_File
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_File
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_File
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_File
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx 
VALIDATE $? "Restarting nginx"