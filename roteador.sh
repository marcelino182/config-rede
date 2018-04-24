#!/bin/bash
case $1 in
	stop)

	echo "Desabilitando Roteamento..."
	echo 0 > /proc/sys/net/ipv4/ip_forward
	echo "OK"

	echo "Limpando Regras..."
	sudo iptables -F
	sudo iptables -X
	sudo iptables -t nat -F
	sudo iptables -t nat -X
	echo "OK"
	
	;;

	start)
	$0 stop
	sleep 2
	echo "Inicializando regras ..."
	sudo iptables -P INPUT DROP
	sudo iptables -P OUTPUT DROP
	sudo iptables -P FORWARD DROP
	echo "OK"

	echo "Liberando acesso Local..."
	sudo iptables -A INPUT -i lo -j ACCEPT
	sudo iptables -A FORWARD -i lo -j ACCEPT
	echo "OK"

	echo "Liberando PING..."
	sudo iptables -A INPUT -p icmp -j ACCEPT
	echo "OK"

	echo "Liberando DNS..."
	sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
	sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT
	sudo iptables -A FORWARD  -p udp --dport 53 -j ACCEPT
	sudo iptables -A FORWARD -p udp --sport 53 -j ACCEPT
	echo "OK"

	echo "Liberando HTTP, HTTPS..."
	sudo iptables -A INPUT -p tcp  -m multiport --dport 80,443 -j ACCEPT
	sudo iptables -A INPUT -p tcp -m multiport --sport 80,443 -j ACCEPT
	sudo iptables -A FORWARD -p tcp -m multiport --dport 80,443 -j ACCEPT
	sudo iptables -A FORWARD -p tcp -m multiport --sport 80,443 -j ACCEPT
	echo "OK"

	echo " Fazendo NAT ..."
	sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
	echo "OK"

	echo "Liberando a saida ..."
	sudo iptables -A OUTPUT -j ACCEPT
	echo "OK"

	echo "Habilitando Roteamento..."
	echo 1 > /proc/sys/net/ipv4/ip_forward
	echo "OK"
	exit 1
	;;

	status)
	echo "Mostrando as regras"
	echo "Table NAT"
	sudo iptables -t nat -L
	echo "TABLE PADRAO"
	sudo iptables -L
	exit 1
	;;
	
	restart)
	$0 stop
	sleep 2
	$0 start
	;;

	*)
	echo "Usage: $0 {start|stop|status|restart}"
	exit 1
esac
exit 0
