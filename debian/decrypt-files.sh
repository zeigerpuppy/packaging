#!/bin/sh

set -eu

pg_version=
libdir="/usr/lib/postgresql/$pg_version/lib"
secret_files_list="$libdir/pgautofailover_secret_files.metadata"

# Make sure the script is being run as root
if [ "$(id -u)" -ne "0" ]; then
    echo "ERROR: pg-auto-failover-enterprise-pg-$pg_version-setup needs to be run as root"
    echo "HINT: try running \"sudo pg-auto-failover-enterprise-pg-$pg_version-setup\" instead"
    exit 1
fi


echo "
Your use of this software is subject to the terms and conditions of the license
agreement by which you acquired this software. If you are a volume license
customer, use of this software is subject to your volume license agreement.
You may not use this software if you have not validly acquired a license for
the software from Microsoft or its licensed distributors.

BY USING THE SOFTWARE, YOU ACCEPT THIS AGREEMENT.
"

PGAUTOFAILOVER_ACCEPT_LICENSE="${PGAUTOFAILOVER_ACCEPT_LICENSE:-}"

interactive_license=false
while [ -z "$PGAUTOFAILOVER_ACCEPT_LICENSE" ]; do
    interactive_license=true
    echo "Do you accept these terms? YES/NO"
    read -r PGAUTOFAILOVER_ACCEPT_LICENSE
done

case "$PGAUTOFAILOVER_ACCEPT_LICENSE" in
    YES );;
    y|Y|Yes|yes )
        echo "ERROR: Only YES is accepted (all capital letters)"
        exit 1;
        ;;
    * )
        echo "ERROR: Terms of the software must be accepted"
        exit 1
esac

if [ $interactive_license = false ]; then
    echo "Accepted terms by using PGAUTOFAILOVER_ACCEPT_LICENSE=YES environment variable"
fi

encryption_disclaimer_text="
Since pg_auto_failover manages failovers, data is sent over the network between
nodes. It is YOUR RESPONSIBILITY as an operator to ensure that this traffic is
secure.

Since pg_auto_failover version 1.3.0 (released 2020-05-07) the traffic between
the different nodes in the cluster is encrypted automatically when using the
--ssl-self-signed flag to create the nodes in the cluster. This is done by
using TLS with self-signed certificates. This means that this does NOT protect
against Man-In-The-Middle attacks. This only protects against passive
eavesdropping on the network.

This automatic TLS setup of self-signed certificates and TLS is NOT DONE when
the cluster was originally created with a pg_auto_failover version before
1.3.0. Even when the cluster is later upgraded to version 1.3.0 or higher.
This is to make sure partially upgraded clusters continue to work.

To enable TLS on these clusters you can use the 'pg_autoctl enable ssl'
command. It's usage is explained in detail here:
https://pg-auto-failover.readthedocs.io/en/stable/security.html#enable-ssl-connections-on-an-existing-setup

Keep in mind that when using --ssl-self-signed the clusters is not safe from
Man-In-The-Middle attacks. To secure the traffic completely you need to follow
the practices outlined here:
https://pg-auto-failover.readthedocs.io/en/stable/security.html#using-your-own-ssl-certificates

Please confirm that you have read this and understand that you should set up
TLS yourself to send traffic between nodes securely:
YES/NO?"

PGAUTOFAILOVER_ACCEPT_ENCRYPTION_DISCLAIMER="${PGAUTOFAILOVER_ACCEPT_ENCRYPTION_DISCLAIMER:-}"
while [ -z "$PGAUTOFAILOVER_ACCEPT_ENCRYPTION_DISCLAIMER" ]; do
    echo "$encryption_disclaimer_text"
    read -r PGAUTOFAILOVER_ACCEPT_ENCRYPTION_DISCLAIMER
done

case "$PGAUTOFAILOVER_ACCEPT_ENCRYPTION_DISCLAIMER" in
    YES );;
    y|Y|Yes|yes )
        echo "ERROR: Only YES is accepted (all capital letters)"
        exit 1;
        ;;
    * )
        echo "ERROR: Disclaimer about encrypted traffic must be accepted before installing"
        exit 1
esac

# create a temporary directory for gpg to use so it doesn't output warnings
temp_gnupghome="$(mktemp -d)"
PGAUTOFAILOVER_LICENSE_KEY="${PGAUTOFAILOVER_LICENSE_KEY:-}"
while [ -z "$PGAUTOFAILOVER_LICENSE_KEY" ]; do
    echo ''
    echo 'Please enter license key:'
    read -r PGAUTOFAILOVER_LICENSE_KEY
done

# Try to decrypt the first file in the list to check if the key is correct
if ! gpg --output "/dev/null" \
        --batch --no-tty --yes --quiet \
        --passphrase "$PGAUTOFAILOVER_LICENSE_KEY" \
        --homedir "$temp_gnupghome" \
        --decrypt "$(head -n 1 "$secret_files_list").gpg" 2> /dev/null; then
    echo "ERROR: Invalid license key supplied"
    exit 1
fi

echo "License key is valid"
echo "Installing..."

decrypt() {
    path_unencrypted="$1"
    path_encrypted="$path_unencrypted.gpg"
    # decrypt the encrypted file
    gpg --output "$path_unencrypted" \
        --batch --no-tty --yes --quiet \
        --passphrase "$PGAUTOFAILOVER_LICENSE_KEY" \
        --homedir "$temp_gnupghome" \
        --decrypt "$path_encrypted"

    # restore permissions and ownership
    chmod --reference "$path_encrypted" "$path_unencrypted"
    chown --reference "$path_encrypted" "$path_unencrypted"
}

# Decrypt all the encrypted files
while read -r path_unencrypted; do
    decrypt "$path_unencrypted"
done < "$secret_files_list"

decrypt /opt/pg_autoctl
mv /opt/pg_autoctl /usr/bin/pg_autoctl
chmod +x /usr/bin/pg_autoctl


# remove the temporary gpg directory
rm -rf "$temp_gnupghome"
