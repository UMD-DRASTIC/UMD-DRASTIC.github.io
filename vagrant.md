---
layout: page
title: Bringing up DRAS-TIC in Vagrant
permalink: /vagrant/
---

# Drastic in a Multi-Machine Vagrant Environment

This local environment is built with exactly the same Ansible playbooks that are used on real clusters. The resulting machines are similar enough to be useful for DRAS-TIC development and testing.

*Note* A "deploy_local_code" variable is set in Vagrantfile passed to the Ansible playbooks. When set to true, Ansible will deploy local sources from directories next to drastic-deploy. When set to false, the master branch of DRAS-TIC code is obtained, compiled, and deployed from the online git repositories. Please continue to use a branch for any major feature development.

*NOTE* that when switching between git branches of drastic-deploy it may be necessary to destroy and recreate the Vagrant environment, especially since some branches use an entirely different version of Cassandra.

## Step by Step

1) Install Vagrant for your operating system and verify that it works: [Get Vagrant](https://www.vagrantup.com)

2) Clone the drastic-deploy git repository:

    $ git clone https://github.com/UMD-DRASTIC/drastic-deploy.git
    $ cd drastic-deploy

3) If the DataStax version of Cassandra is being used, you will need to configure your DataStax account details in order to connect to their APT repository. Check for a "use_datastax" variable in the drastic-deploy project's Vagrantfile. The account information is placed outside of the git repository, in your local Vagrant settings file, ~/.vagrant.d/Vagrantfile, as follows:

    # -*- mode: ruby -*-
    # vi: set ft=ruby :
    $datastax_email = "my_email@example.com"
    $datastax_password = "my_datastax_password"

3) Bring up the Vagrant environment

    $ vagrant up

If you use a different virtualization "provider" than VirtualBox, please supply the appropriate arguments. (E.G. --provider libvirt) This setup has been tested against vbox and libvirt.

4) Go make several cups of coffee. This can take 10 or 20 minutes, depending on your network connection and host machine.

The "vagrant up" command creates three virtual machines, two Cassandra nodes and one web server. Many software packages and libraries will be downloaded as
DRAS-TIC is configured locally.

## Vagrant Machines

The environment includes these machines:

* node-1: Cassandra database node (seed node)
* node-2: Cassandra database node
* node-3: DRAS-TIC webserver

The DRAS-TIC webserver will have an HTTP server running on port 80, which is forwarded to 8080 on your host machine. To reach the DRAS-TIC web interface, point your browser to: http://localhost:8080/.

If you find that the web server is not available when "vagrant up" completes, I've often found it helps to issue as "vagrant reload" command. This reestablishes the forwarding of node-3's port 80 to the local port 8080.
