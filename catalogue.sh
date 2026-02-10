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
dnf module disable nodejs -y &>>LOG_File
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_File
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_File
VALIDATE $? "Installing nodejs:20"

#Here we are writing logic to understand if roboshop user is already existing or not to make script idempotent
id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOG_File
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created..$Y Skipping$N"
fi

mkdir -p /app #Will create /app directory only if it does not exists
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_File
VALIDATE $? "Downloading Catalogue"

#Before unzipping if there was already data existing in /app it will create unnecessary duplication. So make sure to delete content in /app/*
rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_File
VALIDATE $? "unzipping catalogue"

npm install &>>$LOG_File
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>$LOG_File
systemctl enable catalogue  &>>$LOG_File
systemctl start catalogue
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo 
dnf install mongodb-mongosh -y &>>$LOG_File
VALIDATE $? "Installing MongoDB Client"

#Here we are writing logic to check if data already loaded or not. Refer google

STATUS=$(mongosh --host mongodb.komatilanka.store --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ] #if data already exists then output will be more that 0 so here logic is if output less than 0 then it will load the data
then
    mongosh --host mongodb.komatilanka.store </app/db/master-data.js &>>$LOG_File
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi
