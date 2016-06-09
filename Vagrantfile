Vagrant.configure(2) do |config|
  config.vm.box = "hashicorp/precise64"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.synced_folder ".", "/vagrant", nfs: false

  # Privileged false?
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y ruby1.9.1 ruby1.9.1-dev \
      rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 \
      build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev \
      git libxslt-dev libxml2-dev postgresql postgresql-contrib \
      libpq-dev
    sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 \
         --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz \
                        /usr/share/man/man1/ruby1.9.1.1.gz \
        --slave   /usr/bin/ri ri /usr/bin/ri1.9.1 \
        --slave   /usr/bin/irb irb /usr/bin/irb1.9.1 \
        --slave   /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1
    sudo -u postgres createuser --superuser $USER
    printf "install: --no-rdoc --no-ri\nupdate: --no-rdoc --no-ri\n" >> ~/.gemrc
    sudo -u postgres createuser -s vagrant
    sudo gem install bundler

    # Encoding issues...

    sudo su - postgres

    psql

    update pg_database set datistemplate=false where datname='template1';
    drop database Template1;
    create database template1 with owner=postgres encoding='UTF-8' lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0;

    update pg_database set datistemplate=true where datname='template1';

  SHELL
end

# Fixing encoding issues
#
# sudo su postgres
#
# psql
#
# update pg_database set datistemplate=false where datname='template1';
# drop database Template1;
# create database template1 with owner=postgres encoding='UTF-8'
#   lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0;
#
# update pg_database set datistemplate=true where datname='template1';

# rake db:create db:setup
