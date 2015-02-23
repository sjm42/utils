policyfinder
============

Given a list of IP prefixes, this utility will find and print out all matching address
book entries, including address-sets, and all policies that refer to any
matching addresses or address-sets.

Please note that whole policies will be printed,
and they may refer to address-book entries that are not listed,
because those entries do not match any given IP prefixes.
Likewise, any referenced application definitions are not listed.

First save your firewall config on Junos:

```
show configuration | display set | save my-set-config.txt
```

Then copy the textfile on your computer and use this utility.


Dependencies
------------

The script is written in Python. You will need the IPy module,
which can be installed like this on an Ubuntu system:

sudo apt-get install python-ipy



Example
=======
```
./policyfinder fw.set.conf 10.42.42.0/24

set security address-book global address NET_Admin 10.42.42.0/24
set groups policy-to-SRV_1 security policies from-zone OFFICE to-zone <*> policy xyz match source-address NET_SEC_Admin
set groups policy-to-SRV_1 security policies from-zone OFFICE to-zone <*> policy xyz match source-address NET_Admin
set groups policy-to-SRV_1 security policies from-zone OFFICE to-zone <*> policy xyz match destination-address any-ipv4
set groups policy-to-SRV_1 security policies from-zone OFFICE to-zone <*> policy xyz match application any-tcp10m-udp-icmp
set groups policy-to-SRV_1 security policies from-zone OFFICE to-zone <*> policy xyz then permit
set groups policy-OFFICE-to-CUS security policies from-zone OFFICE to-zone <*> policy admin match source-address NET_SEC_Admin
set groups policy-OFFICE-to-CUS security policies from-zone OFFICE to-zone <*> policy admin match source-address NET_Admin
set groups policy-OFFICE-to-CUS security policies from-zone OFFICE to-zone <*> policy admin match destination-address any-ipv4
set groups policy-OFFICE-to-CUS security policies from-zone OFFICE to-zone <*> policy admin match application any-tcp10m-udp-icmp
set groups policy-OFFICE-to-CUS security policies from-zone OFFICE to-zone <*> policy admin then permit
set security policies from-zone OFFICE to-zone CUS7 policy asdf match source-address NET_SEC_Admin
set security policies from-zone OFFICE to-zone CUS7 policy asdf match source-address NET_Admin
set security policies from-zone OFFICE to-zone CUS7 policy asdf match destination-address any-ipv4
set security policies from-zone OFFICE to-zone CUS7 policy asdf match application any-tcp10m-udp-icmp
set security policies from-zone OFFICE to-zone CUS7 policy asdf then permit
```

So there. Cheers!
