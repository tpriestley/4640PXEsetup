#!/bin/bash
TIM_URL=https://github.com/timoguic/ACIT4640-todo-app.git
APP_FOLDER=/home/todoapp/app
SETUP_DIR=/home/admin/setup
#end of variables
#firewall setup
sudo setenforce 0
sed 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo firewall-cmd --zone=public --add-port=8080/tcp
sudo firewall-cmd --zone=public --add-service=http
sudo firewall-cmd --runtime-to-permanent
#git install and user setup
sudo dnf install -y git
sudo useradd todoapp
#install app fromn git
sudo git clone $TIM_URL $APP_FOLDER/
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
#install nodejs and mongo
sudo dnf install -y nodejs
sudo cp $SETUP_DIR/mongodb-org-4.4.repo /etc/yum.repos.d/
sudo dnf install -y mongodb-org
#mongo config and ownership
sudo cp $SETUP_DIR/database.js $APP_FOLDER/config/
sudo chown mongod:mongod /tmp/mongodb-27017.sock
sudo systemctl start mongod
#install dependencies
sudo npm install --folder $APP_FOLDER/
#fix permissions
sudo chown -R todoapp:todoapp /home/todoapp/
sudo chmod 755 /home/todoapp/
#copy service
sudo cp $SETUP_DIR/todoapp.service /etc/systemd/system/
sudo systemctl daemon-reload
#install and enable nginx
sudo dnf install -y epel-release
sudo dnf install -y nginx
sudo cp $SETUP_DIR/nginx.conf /etc/nginx/
sudo systemctl enable nginx
sudo systemctl start nginx
