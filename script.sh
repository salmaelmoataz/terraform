#!/bin/bash
sudo yum install httpd
sudo systemctl enable httpd
sudo systemctl start httpd
sudo cp /home/ec2-user/phpscript.php /var/www/html