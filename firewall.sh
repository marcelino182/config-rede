#!/bin/bash
#/etc/init.d/firewall
#chkconfig: -08 92
#description firewall


##############DEFINICOES############################
MODPROBE=/sbin/modprobe
IPTABLES=iptables
prog=firewall


$MODPROBE ip_conntrack_ftp
$MODPROBE ip_nat_ftp


IFACE_LO="lo"
IP_IFACE_LO="127.0.0.1"

IFACE_EXT="enp0s8"
IP_IFACE_EXT="10.0.0.106"
IP_REDE_EXT="10.0.0.0/24"
IP_BROADCAST_EXT="10.0.0.255"
MASC_REDE_EXT="255.255.255.0"


IFACE_INT="enp0s3"
IP_IFACE_INT="192.168.5.2"
IP_REDE_INT="192.168.5.0/24"
IP_BROADCAST_INT="192.168.5.255"
MASC_REDE_INT="255.255.255.0"

case "$1" in

start)
##DESABILITA ROTEAMENTO 
echo "0" > /proc/sys/net/ipv4/ip_forward

###########Tabela Filter#####################
$IPTABLES -F #flush
$IPTABLES -X #apaga todas as  chain dos usuarios

#Politica padrao bloquear tudo 
$IPTABLES -P INPUT DROP 
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP

#Chain INPUT ############

#statefull ########
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#REDES INTERNAS 
#broadcast redes  internas
$IPTABLES -A INPUT -p ALL -i $IFACE_INT -d $IP_BROADCAST_INT -j ACCEPT 
#localhost
$IPTABLES -A INPUT -p ALL -i $IFACE_LO -s $IP_IFACE_LO -j ACCEPT
$IPTABLES -A INPUT -p ALL -i $IFACE_LO -s $IP_IFACE_INT -j ACCEPT
$IPTABLES -A INPUT -p ALL -i $IFACE_LO -s $IP_IFACE_EXT -j ACCEPT
#rede interna 
$IPTABLES -A INPUT -p ALL -i $IFACE_INT -s $IP_IFACE_INT -j ACCEPT

##PING (ICMP) em qual interface
$IPTABLES -A INPUT -p icmp -j ACCEPT

##SSH #####
$IPTABLES -A INPUT -p tcp -i $IFACE_INT -s $IP_REDE_INT -d $IP_IFACE_INT --dport 22 -j ACCEPT 

##SQUID####
$IPTABLES -A INPUT -p tcp  -i $IFACE_INT -s $IP_REDE_INT -d $IP_IFACE_INT --dport 3128 -j ACCEPT

###DNS#####
$IPTABLES -A INPUT -p udp  --sport 53 -j ACCEPT
$IPTABLES -A INPUT -p udp  --dport 53 -j ACCEPT 
#Chain FORWARD ###

#statefull###

#$IPTABLES -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#spoofing##
#ext"
#$IPTABLES -A FORWARD -o $IFACE_EXT -d $IP_REDE_INT -j DROP
#$IPTABLES -A FORWARD -i $IFACE_EXT -s $IP_REDE_INT -j DROP
#int
#$IPTABLES -A FORWARD -o $IFACE_INT -d ! $IP_REDE_INT -j DROP
#$IPTABLES -A FORWARD -i $IFACE_INT -s ! $IP_REDE_INT -j DROP

##ftp,dns,http,https,squid##
$IPTABLES -A FORWARD  -p tcp -m multiport --dports 21,53,80,443,3128 -j ACCEPT
$IPTABLES -A FORWARD  -p tcp -m multiport --sports 21,53,80,443,3128 -j ACCEPT
##dns upd
$IPTABLES -A FORWARD -p udp  --dport 53 -j ACCEPT
$IPTABLES -A FORWARD -p udp  --sport 53 -j ACCEPT


##Chain OUTPUT

$IPTABLES -A OUTPUT -p ALL -s $IP_IFACE_LO -j ACCEPT
$IPTABLES -A OUTPUT -p ALL -s $IP_IFACE_INT -j ACCEPT
$IPTABLES -A OUTPUT -p ALL -s $IP_IFACE_EXT -j ACCEPT

##############TABELA NAT###############################
###FLUSH###############
$IPTABLES  -t nat -F
###Apaga chains dos usuarios
$IPTABLES -t nat -X

###politicas padrao ####

###criar chain usuarios ####

##regras chain usuarios ####
# proxy transparente -  direciona os pacotes http porta 80 para a porta do squid 3128
$IPTABLES -t nat -A PREROUTING -i $IFACE_INT -p tcp --dport 80 -j REDIRECT --to-port 3128
# NAT compartilhamento de internet
$IPTABLES -t nat -A POSTROUTING -s $IP_REDE_INT -o  $IFACE_EXT -j MASQUERADE

##chain OUTPUT ####

############TABELA MANGLE #################################
###FLUSH
$IPTABLES -t mangle -F
#APAGAR REGRAS DE USUARIO
$IPTABLES -t mangle -X

##########HABILITANDO O ROTEAMENTO
echo "1" > /proc/sys/net/ipv4/ip_forward

;;

stop)
###RESTAURANDO AS POLITICAS PADRAO DA TABELA FILTER ##############
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
####RESTAURANDO AS POLITICAS PADRAO DA TABELA NAT ################
$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT
#####RESTAURANDO AS POLITICAS PADRAO DA TABELA MANGLE ##############
$IPTABLES -t mangle -P PREROUTING ACCEPT
$IPTABLES -t mangle -P INPUT ACCEPT
$IPTABLES -t mangle -P FORWARD ACCEPT
$IPTABLES -t mangle -P OUTPUT ACCEPT
$IPTABLES -t mangle -P POSTROUTING ACCEPT
#flush
$IPTABLES -F
$IPTABLES -X
$IPTABLES -t nat -F
$IPTABLES -t nat -X
$IPTABLES -t mangle -F
$IPTABLES -t mangle -X
;;

status)
echo ""
echo "TABELA FILTER"
echo ""
$IPTABLES -L -n
echo ""
echo "TABELA MANGLE"
$IPTABLES -t mangle -L -n
echo ""
echo "TABELA NAT"
$IPTABLES -t nat -L -n
echo""
echo "ROTEAMENTO"
sudo cat /proc/sys/net/ipv4/ip_forward
;;

restart)
$0 stop
$0 start
;;

*)
echo $"Usage: $0 {start|stop|status|restart|}"
exit 1
;;

esac

exit $?

