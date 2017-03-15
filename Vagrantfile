# -*- mode: ruby -*-
# vi: set ft=ruby :

$SERVER_SCRIPT = <<EOF
touch /var/log/vagrant-ipa-setup.log; \
source /vagrant/config/server_config/config.sh | tee -a /var/log/vagrant-ipa-setup.log;\
sh /vagrant/config/server_config/install.sh    | tee -a /var/log/vagrant-ipa-setup.log;
EOF

$CLIENT_SCRIPT = <<EOF
touch /var/log/vagrant-ipa-setup.log; \
source /vagrant/config/client_config/config.sh | tee -a /var/log/vagrant-ipa-setup.log;\
sh /vagrant/config/client_config/install.sh    | tee -a /var/log/vagrant-ipa-setup.log;
EOF

# The latest version of Vagrant uses the short hostname rather than FQDN.
# ipa-server and client don't like this
$HOSTNAME_SCRIPT = <<EOF
hostname $(hostname -f)
hostname > /etc/hostname
EOF

# NetworkManager overwrites /etc/resolv.conf at boot.. just change it back.
$RESOLV_SCRIPT = <<EOF
cp /vagrant/config/resolv.conf /etc/resolv.conf
EOF

Vagrant.configure("2") do |config|
  config.vm.box = "fedora/23-cloud-base"
  #config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/fedora-18-x64-vbox4210.box"

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on the "Usage" link above
    config.cache.scope = :box
  end

  if !Vagrant.has_plugin?("vagrant-hostsupdater")
    # Update /etc/hosts
    puts 'Install the required plugin `vagrant-hostsupdate` to sync /etc/hosts with the VMs:'
    puts '  $ vagrant plugin install vagrant-hostsupdater'
  end

  config.vm.define :ipaserver do |ipaserver|
    ipaserver.vm.network :forwarded_port, guest: 80, host: 8080
    ipaserver.vm.network :forwarded_port, guest: 443, host: 1443
    ipaserver.vm.network :private_network, ip: "192.168.19.15"
    ipaserver.vm.hostname = "ipaserver.example.com"
    ipaserver.vm.provision :shell, :inline => $HOSTNAME_SCRIPT
    ipaserver.vm.provision :shell, :inline => $SERVER_SCRIPT
    ipaserver.vm.provision :shell, :inline => $RESOLV_SCRIPT, :run => 'always'
    ipaserver.vm.provider :libvirt do |domain|
        domain.memory = 2048
        domain.cpus = 2
    end
  end

  config.vm.define :client do |client|
    client.vm.network :forwarded_port, guest: 80, host: 8888
    client.vm.network :forwarded_port, guest: 443, host: 2443
    client.vm.network :private_network, ip: "192.168.19.20"
    client.vm.hostname = "client.example.com"
    client.vm.provision :shell, :inline => $HOSTNAME_SCRIPT
    client.vm.provision :shell, :inline => $CLIENT_SCRIPT
    client.vm.provision :shell, :inline => $RESOLV_SCRIPT, :run => 'always'
    client.vm.provider :libvirt do |domain|
        domain.memory = 2048
        domain.cpus = 2
    end
  end
end
