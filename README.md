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

  - The Vagrant VM is configured by Vagrantfile will be provisioned with Java, Tomcat, Git (include Git daemon), these cookbooks was obtained
from Opscode Github to the local cookbooks/ directory. All cookbooks needed are apt, java, tomcat, runit, git.
  - Tomcat home directory at default location /var/lib/tomcat6, Git base path is /srv/git (the `repository` repo needs to create manually)
  - Forwarded ports: 8080 (tomcat) => 8005 and 9418 (git daemon) => 8006
  - All scenario processes is in the uc4 bash script. This script will run as a daemon and relied on the inotifywait (in inotify-tools package) 
to listen on the /vagrant/delivery directory for new file.
  - After uc4 daemon started, it will waiting for new files on /vagrant/delivery, when a new archive is created, it will extract to a temp
directory (/tmp/vagrant-tmp/), try to parse the manifest.txt file then add and commit specified files to Git repo. If the specified file is *.war archive, it will 
copy the archive to Tomcat's webapps directory.


Problems & considerations:
  - The inotifywait seems does not work properly with network filesystem, so if I create or copy a new file on /vagrant/delivery from the host machine (Windows, as the /vagrant directory was mounted as a bridge between host/guest machine), 
inotifywait cannot detect (refer: http://stackoverflow.com/questions/4231243/inotify-with-nfs). So this solution will ONLY work properly if the new file event was emitted inside the Vagrant VM (guest machine)
  - Startup problem: If I use the /etc/init.d/uc4-service to start uc4 daemon at startup (from /etc/rc.local), the /vagrant directory seems does not
mounted yet so the logs (/vagrant/logs) may not available. To test, I often manually start uc4 daemon after ssh to VM.
  - Should we spawn threads from the daemon process to allow parallel process? 
  - Bash script works fine in most cases, but it's hard to handle error, logging, manage threads. So I still think we can use a higher level language to write the daemon, Python or Java looks good to write daemon and efficient in logging, spawn threads, Python also suport Pyinotify to leverage inotify. 
  - It's better if we can leverage a Git client library (!?).
  - The war archive may failed to deploy inside Tomcat due to some other reasons from Tomcat side, can we track these things?