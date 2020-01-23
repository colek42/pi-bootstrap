configure
set protocols bgp 64512 parameters router-id 192.168.0.1
set protocols bgp 64512 neighbor 172.4.20.10 remote-as 64512
set protocols bgp 64512 neighbor 172.4.20.11 remote-as 64512
set protocols bgp 64512 neighbor 172.4.20.12 remote-as 64512
set protocols bgp 64512 redistribute static
commit; save
exit