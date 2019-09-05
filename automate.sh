#This script was created by: Landon Hise
#Steps taken researched and tested by: Nicholas Shorter
#
#Stephen F. Austin State University Undergraduate Research 2019
#
#Purpose: To automate adding additional node servers to a compute cluster
#using JohnTheRipper to crack passwords
#usage: ./automate.sh [desired name of node]

#fail conditions
#-------------------------------------------------------------------------------
#verify user is root
  if [ "$EUID" -ne 0 ]
    then echo "Please run this script as root."
         echo "Exiting script..."
    exit 0
  fi

#script only takes one argument: current node's hostname
  if [ $# -ne 1 ]
    then echo "This script only accepts one argument: The username of the current node."
         echo "Example: './automate.sh workernodex'  where 'x' is the current nodes assigned digit."
         echo "Exiting script..."
    exit 0
  fi
#-------------------------------------------------------------------------------
#fail conditions end


#install sudo
echo "----------STATUS: installing sudo package if not already present"
  sleep 3s

  apt install sudo -y


#create group "main" and add current node to it
echo "----------STATUS: creating group main"
  groupadd main
  usermod -aG main $1

#create user master
echo "----------STATUS: creating master user and adding to group main"
  sleep 3s

  useradd -m master
  echo "master:master" | chpasswd
  usermod -aG main master


#add group "main" to sudoers file
echo "----------STATUS: adding "$1" to group main. granting main sudo permissions"
  sleep 3s

  echo "#user "$1" and master node are granted sudo permissions on this machine" >> /etc/sudoers
  echo ""$1"  ALL=(ALL:ALL) ALL" >> /etc/sudoers
  echo "master ALL=(ALL:ALL) ALL" >> /etc/sudoers

#export PATH variable
echo "----------STATUS: exporting PATH variable"
  sleep 3s

  echo 'export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin' >> ~/.bash_profile


#install net-tools
echo "----------STATUS: installing net-tools"
  sleep 3s

  apt install net-tools -y


#install nfs, configure folder in "/" (node version)
#process is different for master, but is a one-time setup
echo "----------STATUS: creating nfsshare directory in / and configuring"
  sleep 3s

  apt install nfs-common -y
  cd /
  mkdir nfsshare
  chmod 777 /nfsshare
  echo '192.168.0.20:/nfsshare /nfsshare nfs defaults' >> /etc/fstab
  #     ^^^^^^^^^^^^--------> current master's IP, subject to change
  #mount -a


#update packages and install dependencies for john and rexgen
echo "----------STATUS: installing dependencies for JTR and rexgen"
  sleep 3s

  apt update -y
  apt install build-essential libssl-dev yasm libgmp-dev libpcap-dev libnss3-dev -y
  apt install libkrb5-dev pkg-config libopenmpi-dev openmpi-bin zlib1g-dev libbz2-dev -y
  apt install flex cmake bison git -y

#installation steps
#-------------------------------------------------------------------------------
#rexgen install
echo "----------STATUS: installing and configuring rexgen"
  sleep 3s

  #rexgen install/configure
  cd /usr/local
  git clone https://github.com/teeshop/rexgen.git
  cd rexgen
  ./install.sh
  ldconfig

#JTR install
echo "----------STATUS: installing and configuring JTR"
  sleep 3s

  #JTR install/configure steps
  cd /usr/local
  git clone https://github.com/magnumripper/JohnTheRipper.git
  chmod 777 -R /usr/local/JohnTheRipper
  cd JohnTheRipper/src
  ./configure --enable-mpi
  make -s clean && make -sj4
  cd ../run
  ./john --test

exit 0
