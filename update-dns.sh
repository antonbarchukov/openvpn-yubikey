#!/bin/bash

# openvpn-yubikey dns handler
# called by openvpn on connect/disconnect

DNS_SERVERS=""
SEARCH_DOMAINS=""

# Try new-style dns_server_* vars (OpenVPN 2.6+ dns push directive)
for var in $(env | grep "^dns_server_.*_address_" | cut -d= -f1); do
    DNS_SERVERS="$DNS_SERVERS ${!var}"
done
for var in $(env | grep "^dns_server_1_resolve_domain_" | cut -d= -f1); do
    SEARCH_DOMAINS="$SEARCH_DOMAINS ${!var}"
done

# Fallback: parse foreign_option_* vars (traditional dhcp-option push)
if [ -z "$(echo $DNS_SERVERS | xargs)" ]; then
    for var in $(env | grep "^foreign_option_" | cut -d= -f1); do
        val="${!var}"
        case "$val" in
            *"dhcp-option DNS "*)
                DNS_SERVERS="$DNS_SERVERS ${val##*dhcp-option DNS }"
                ;;
            *"dhcp-option DOMAIN-SEARCH "*)
                SEARCH_DOMAINS="$SEARCH_DOMAINS ${val##*dhcp-option DOMAIN-SEARCH }"
                ;;
            *"dhcp-option DOMAIN "*)
                SEARCH_DOMAINS="$SEARCH_DOMAINS ${val##*dhcp-option DOMAIN }"
                ;;
        esac
    done
fi

DNS_SERVERS=$(echo $DNS_SERVERS | xargs)
SEARCH_DOMAINS=$(echo $SEARCH_DOMAINS | xargs)

case "$script_type" in
    up)
        mkdir -p /etc/resolver
        rm -f /tmp/vpn-resolver-domains

        for domain in $SEARCH_DOMAINS; do
            echo "nameserver ${DNS_SERVERS%% *}" > /etc/resolver/$domain
            if [ "${DNS_SERVERS%% *}" != "${DNS_SERVERS##* }" ]; then
                echo "nameserver ${DNS_SERVERS##* }" >> /etc/resolver/$domain
            fi
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
