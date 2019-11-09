configure
set protocols bgp 64512 parameters router-id 192.168.0.1
set protocols bgp 64512 neighbor 172.4.20.3 remote-as 64512
set protocols bgp 64512 neighbor 172.4.20.4 remote-as 64512
set protocols bgp 64512 neighbor 172.4.20.5 remote-as 64512
set protocols bgp 64512 redistribute static
commit; save
exit