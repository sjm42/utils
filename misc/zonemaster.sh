#!/bin/sh
#
# This is a frightening shell script that attempts to install Zonemaster
# on a CentOS 6 host.
#
# Requirements:
#  * a fresh and up-to-date CentOS 6 installation (run yum update -y)
#  * a working internet connection
#  * an hour of time, or so
#
# Potential problems:
#  * locale issues may arise with the database, please use UTF-8 enconding.
#  * the postgres installation will use the default tcp port.
#  * some CPAN modules may break, we are installing the latest available.
#
# Alongside with Zonemaster software, this installation will include:
#  * Devel tools from Centos rpm repo#
#  * PostgreSQL 9.5 or later, downloaded and installed
#  * Perl 5.24.0 or later, downloaded and installed
#  * A huge pile of CPAN modules, downloaded and installed


ZMROOT=/opt/zonemaster
my_cpan=/opt/zonemaster/bin/cpan
my_perl=perl-5.24.0
zm_perl=$ZMROOT/bin/perl
cp="/bin/cp -f"

work=$HOME/zm-work
mkdir -p $work
cd $work

# Install some necessary libraries, and devel tools
yum install -y wget git lsof ldns ldns-devel openssl-devel libidn-devel || exit 1
yum groupinstall -y "Development Tools" || exit 1

# Download, build and install Perl
wget http://www.cpan.org/src/5.0/$my_perl.tar.gz || exit 1
tar xzf $my_perl.tar.gz
cd $my_perl || exit 1
./Configure -des -Dprefix=$ZMROOT -Dcc=gcc -DMAILDOMAIN=localhost -Dcf_email=root@localhost -Dperladmin=root@localhost 2>&1 | tee -a 00build.log
make 2>&1 | tee -a 00build.log
make test || exit 1
make install 2>&1 | tee -a 00build.log

# Start installing Perl/CPAN modules
cd $HOME/zm-work
yes | $my_cpan -i CPAN

# This module will try to interact with terminal during the test phase.
$my_cpan -i -T Term::ReadLine::Perl

$my_cpan -u
$my_cpan -i Bundle::CPAN

# Don't ask why "cpan -i" does not work with these. It does not.
echo "install ETHER/libwww-perl-6.15.tar.gz" | $zm_perl -MCPAN -e shell
echo "install GUIDO/libintl-perl-1.26.tar.gz" | $zm_perl -MCPAN -e shell

# Install a shitload of Perl/CPAN modules.
$my_cpan -i Devel::CheckLib Test::Fatal Test::Pod Pod::Coverage \
  ExtUtils::MakeMaker ExtUtils::ParseXS Archive::Zip File::Remove \
  Test::DependentModules Test::Output Role::Tiny Readonly Time::HiRes \
  List::MoreUtils DateTime IO::String Regexp::Common Hash::Merge \
  Mail::RFC822::Address Module::Find Readonly::XS Tie::Simple </dev/null || exit 1
$my_cpan -i IO::Socket::INET6 File::ShareDir File::Slurp JSON YAML \
  Module::Signature Net::IP::XS Net::LDNS JSON::XS Moose Moo </dev/null || exit 1

# Install Zonemaster engine
$my_cpan -i Zonemaster || exit 1

# Moar CPAN modules
$my_cpan -i Config::IniFiles Daemon::Control JSON::RPC JSON::RPC::Dispatch \
  Parallel::ForkManager Plack::Builder Plack::Middleware::Debug \
  Router::Simple::Declare Starman YAML::Tiny \
  Module::Install IO::CaptureOutput String::ShellQuote </dev/null || exit 1

# Install Zonemaster CLI
$my_cpan -i Zonemaster::CLI || exit 1


# Download, install, initialize and start PostgreSQL

cd $work
wget https://download.postgresql.org/pub/repos/yum/9.5/redhat/rhel-6-x86_64/pgdg-centos95-9.5-2.noarch.rpm || exit 1
yum -y localinstall pgdg-centos95-9.5-2.noarch.rpm
yum -y install postgresql95-devel postgresql95-server

chkconfig postgresql-9.5 on
service postgresql-9.5 initdb

cd /var/lib/pgsql/9.5/data || exit 1
mv pg_hba.conf pg_hba.conf.orig
cat >pg_hba.conf <<'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
# EOF
EOF
service postgresql-9.5 start


# Download and install Zonemaster backend, first install some dependencies

cd $work
POSTGRES_HOME=/usr/pgsql-9.5
export POSTGRES_HOME
$my_cpan -i DBI DBD::SQLite DBD::Pg || exit 1

git clone https://github.com/dotse/zonemaster-backend.git || exit 1
cd $work/zonemaster-backend || exit 1

# Fix the code a bit. This is HORRIBLE.
$zm_perl -pi -e "s/^.*=\s*'SOME\s+OTHER\s+\w+'\s+if\s*\(.*;//" \
  ./lib/Zonemaster/WebBackend/Engine.pm
$zm_perl -pi -e 's|^#!/usr/bin/env perl.*|#!/opt/zonemaster/bin/perl|' \
  script/zm_wb_daemon

$zm_perl Makefile.PL || exit 1
make test || exit 1
make install || exit 1

cd share || exit 1
mv backend_config.ini backend_config.ini.orig
cat >backend_config.ini <<'EOF'
[DB]
engine=PostgreSQL
user=zonemaster
password=zonemaster
database_name=zonemaster
database_host=localhost
polling_interval=1

[LOG]
log_dir=logs/

[PERL]
interpreter=/opt/zonemaster/bin/perl

[ZONEMASTER]
max_zonemaster_execution_time=300
number_of_professes_for_frontend_testing=20
number_of_professes_for_batch_testing=20

[GEOLOCATION]

# EOF
EOF
mkdir -p /etc/zonemaster
$cp backend_config.ini /etc/zonemaster/ || exit 1
cd ../


# Initialize the Zonemaster database

$cp docs/initial-postgres.sql /tmp/ || exit 1
su - postgres -c "/usr/pgsql-9.5/bin/psql -f /tmp/initial-postgres.sql"


# Configure Zonemaster background services

adduser zonemast
cat >/etc/init/starman-zonemaster.conf <<'EOF'
description "Zonemaster WebBackend Upstart Job"
start on filesystem or runlevel [2345]
stop on runlevel [!2345]
umask 022
limit nofile 4096 4096
expect fork
pre-start script
  [ -d "/var/log/zonemaster" ] || mkdir -p /var/log/zonemaster
  chown -R zonemast:zonemast /var/log/zonemaster
end script
exec /opt/zonemaster/bin/starman \
  --user=zonemast \
  --group=zonemast \
  --daemonize \
  --listen=127.0.0.1:5000 \
  --max-requests=99999999 \
  --workers=5 \
  --pid=/var/log/zonemaster/zm-web.pid \
  --error-log /var/log/zonemaster/zm-web.log \
  /opt/zonemaster/bin/zonemaster_webbackend.psgi
# EOF
EOF
cat >/etc/init/zm_wb_daemon.conf <<'EOF'
description "Zonemaster WebBackend Runner Daemon"
start on filesystem or runlevel [2345]
stop on runlevel [!2345]
umask 022
limit nofile 4096 4096
expect daemon
pre-start script
  sleep 5
end script
exec /opt/zonemaster/bin/zm_wb_daemon \
  --user=zonemast \
  --group=zonemast \
  --pidfile=/var/log/zonemaster/zm-wb-daemon.pid \
  start
# EOF
EOF
cd ../


# Finally, download and install Zonemaster web GUI

cd $work
$my_cpan -i Dancer Text::Markdown Template JSON </dev/null || exit 1
git clone https://github.com/dotse/zonemaster-gui.git || exit 1
cd zonemaster-gui || exit 1
$zm_perl -pi -e 's|^#!/usr/bin/env perl.*|#!/opt/zonemaster/bin/perl|' \
  zm_app/bin/app.pl

$zm_perl Makefile.PL || exit 1
make || exit 1
make test || exit 1
make install || exit 1


# Configure Zonemaster web GUI service

mkdir -p /opt/zonemaster/share/zonemaster
$cp -a zm_app /opt/zonemaster/share/zonemaster || exit 1
chmod 755 /opt/zonemaster/share/zonemaster/zm_app/bin/app.pl || exit 1

cat >/etc/init/starman-zonemaster-gui.conf <<'EOF'
description "Zonemaster GUI Upstart Job"
start on filesystem or runlevel [2345]
stop on runlevel [!2345]
umask 022
limit nofile 4096 4096
expect fork
pre-start script
  [ -d "/var/log/zonemaster" ] || mkdir -p /var/log/zonemaster
  chown -R zonemast:zonemast /var/log/zonemaster
  sleep 2
end script
exec /opt/zonemaster/bin/starman \
  --user=zonemast \
  --group=zonemast \
  --daemonize \
  --listen=:8000 \
  --max-requests=99999999 \
  --workers=5 \
  --pid=/var/log/zonemaster/zm-web-gui.pid \
  --error-log=/var/log/zonemaster/zm-web-gui.log \
  /opt/zonemaster/share/zonemaster/zm_app/bin/app.pl
# EOF
EOF


# Turn off iptables, otherwise the web gui at port 8000 would be unreachable.
# You could alternatively just open up the tcp port with an iptable rule.

/etc/init.d/iptables stop
/etc/init.d/ip6tables stop
chkconfig iptables off
chkconfig ip6tables off


# Finally, start Zonemaster services

initctl start starman-zonemaster
initctl start zm_wb_daemon
initctl start starman-zonemaster-gui
sleep 10


# Check if it is running...

ps -fu zonemast
curl -X POST http://127.0.0.1:5000/ -d '{"method":"version_info"}'

# {"result":{"zonemaster_backend":"1.0.5","zonemaster_engine":"v1.0.14"},"id":null,"jsonrpc":"2.0"}

exit 0
# EOF
