#!/bin/bash
yum install httpd -y
echo "<h1> Hey the Server Name is $(hostname -f) <h1>" |sudo tee /var/www/html/index.html
systemd enable httpd
systemctl start httpd
