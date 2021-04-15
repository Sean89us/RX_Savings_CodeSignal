#!/bin/bash

# Assume root
sudo su
# Install httpd
yum -y install httpd
# Create the index.html to be served
cat > '/var/www/html/index.html' << EOF
<html>
<h1>Hello World</h1>
<p>Date/Time: <span id="datetime"></span></p>
<script>
var dt = new Date();
document.getElementById("datetime").innerHTML = dt.toLocaleString();
</script>
</html>
EOF
# Enable and start httpd
systemctl enable httpd
systemctl start httpd
