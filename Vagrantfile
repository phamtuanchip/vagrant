# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
   
  config.vm.box = "/Users/tuanp/.vagrant.d/boxes/precise32"
 
  config.vm.network :hostonly, "33.33.33.200"
  config.ssh.max_tries = 10
   
  config.vm.forward_port 8080, 8085
  config.vm.forward_port 9418, 8086
  
  # To configure and run shell provisioner
  config.vm.provision :shell, :path => "scripts/setup.sh"
end
