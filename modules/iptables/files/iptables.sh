# Server names and ports
. `dirname $0`/names
# Interfaces (override in host-specific file if necessary)
export EXT_INTERFACE=eth0
# Flush and remove all chains
iptables -P INPUT  ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X

# Allow all traffic on loopback interface
iptables -I INPUT 1 -i lo -j ACCEPT
iptables -I OUTPUT 1 -o lo -j ACCEPT
# Allow established and related connections
iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I OUTPUT 2 -m state --state ESTABLISHED,RELATED -j
ACCEPT
# Include machine specific settings
HOST_RULES=`dirname $0`/hosts/`hostname -s`
[ -f ${HOST_RULES} ] && . ${HOST_RULES}
[ "${MAIN_IP}" == "" ] && ( echo No MAIN_IP was set, please set the primary IP address in ${HOST_RULES}. ; exit 1 )
# Include common settings
. `dirname $0`/roles/common
# Drop all non-matching packets
iptables -A INPUT -j LOG --log-prefix "INPUT: "
iptables -A INPUT -j DROP
iptables -A OUTPUT -j LOG --log-prefix "OUTPUT: "
iptables -A OUTPUT -j DROP
echo -e "Test remote login and then:\n iptables-save >/etc/iptables.rules"