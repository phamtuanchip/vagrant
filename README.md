Scenario for Solutions Developer
=======

Author: Pham Tuan
Email: phamtuanchip@gmail.com
Date:  Sep 10, 2013


Description:

This archive contains stuffs for test scenario. It includes:
  - Vagrantfile: which is the vagrant descriptor file
  - scripts/: Scripts needed for this scenario and some archives for test
  - README.md: this file


Solution:

  - The Vagrant VM is configured by Vagrantfile will be provisioned with Java, Tomcat, Git (include Git daemon) 
  - Tomcat home directory at default location /var/lib/tomcat6, Git base path is /srv/git (the `repository` repo needs to create manually)
  - Forwarded ports: 8080 (tomcat) => 8005 and 9418 (git daemon) => 8006
  - All scenario processes is in the bash script.  


Problems & considerations:
  -  for futher script to run and execute trigger deployment war when we have deliver I have no time to finish