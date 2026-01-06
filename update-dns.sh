#!/bin/bash

# openvpn-yubikey dns handler
# called by openvpn on connect/disconnect

DNS_SERVERS=""
for var in $(env | grep "^dns_server_.*_address_" | cut -d= -f1); do
    DNS_SERVERS="$DNS_SERVERS ${!var}"
done

SEARCH_DOMAINS=""
for var in $(env | grep "^dns_server_1_resolve_domain_" | cut -d= -f1); do
    SEARCH_DOMAINS="$SEARCH_DOMAINS ${!var}"
done

DNS_SERVERS=$(echo $DNS_SERVERS | xargs)
SEARCH_DOMAINS=$(echo $SEARCH_DOMAINS | xargs)

case "$script_type" in
    up)
        mkdir -p /etc/resolver
        rm -f /tmp/vpn-resolver-domains

        for domain in $SEARCH_DOMAINS; do
            echo "nameserver ${DNS_SERVERS%% *}" > /etc/resolver/$domain
            echo "nameserver ${DNS_SERVERS##* }" >> /etc/resolver/$domain
            echo "$domain" >> /tmp/vpn-resolver-domains
        done
        ;;
    down)
        if [ -f /tmp/vpn-resolver-domains ]; then
            while read domain; do
                rm -f /etc/resolver/$domain
            done < /tmp/vpn-resolver-domains
            rm -f /tmp/vpn-resolver-domains
        fi
        ;;
esac

exit 0
