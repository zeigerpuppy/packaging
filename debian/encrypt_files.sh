#!/bin/bash
set -euo pipefail

if [ -n "${UNENCRYPTED_PACKAGE:-}" ]; then
    exit 0
fi

PACKAGE_ENCRYPTION_KEY="${PACKAGE_ENCRYPTION_KEY:-}"
if [ -z "$PACKAGE_ENCRYPTION_KEY" ]; then
    echo "ERROR: The PACKAGE_ENCRYPTION_KEY environment variable needs to be set"
    echo "HINT: If trying to build packages locally, just set it to 'abc' or something"
    echo "HINT: If you're trying to build unencrypted packages you should set the UNENCRYPTED_PACKAGE environment variable"
    exit 1
fi

# create a temporary directory for gpg to use so it doesn't output warnings
temp_gnupghome="$(mktemp -d)"

encrypt() {
    path_unencrypted="$1"
    path_encrypted="$1.gpg"
    # encrypt the files using password
    # --s2k-* options are there to make sure decrypting/encrypting doesn't
    # take minutes
    gpg --symmetric \
        --batch \
        --no-tty \
        --yes \
        --cipher-algo AES256 \
        --s2k-mode 3 \
        --s2k-count 1000000 \
        --s2k-digest-algo SHA512 \
        --passphrase-fd 0 \
        --homedir "$temp_gnupghome" \
        --output "$path_encrypted" \
        "$path_unencrypted" \
        <<< "$PACKAGE_ENCRYPTION_KEY"

    # keep permissions and ownership the same, so we can restore it later
    # when decrypting
    chmod --reference "$path_unencrypted" "$path_encrypted"
    chown --reference "$path_unencrypted" "$path_encrypted"

    # remove the unencrypted file from the package
    rm "$path_unencrypted"
}

for dir in debian/postgresql-*; do
    # skip postgresql-xxxx.log files
    if [ ! -d "$dir" ]; then
        continue;
    fi;

    # Get PG version from directory name
    # shellcheck disable=SC2001
    pg_version=$(echo "$dir" | sed 's@^debian/postgresql-\([0-9]\+\)-.\+$@\1@g')

    # Copy over postinst and prerm file, but replace "pg_version=" with
    # e.g. "pg_version=12"
    pg_version_regex="s/^pg_version=\$/pg_version=$pg_version/g"

    # Install postinst and prerm files
    debdir="$dir/DEBIAN"
    mkdir -p "$debdir"
    for script in prerm postinst; do
        sed "$pg_version_regex" "debian/package-$script"
        sed "$pg_version_regex" "debian/package-$script" > "$debdir/$script";
        chmod +x "$debdir/$script"
    done


    bindir="$dir/usr/bin"
    mkdir -p "$bindir"
    setup="$bindir/pg-auto-failover-enterprise-pg-$pg_version-setup"
    sed "$pg_version_regex" "debian/decrypt-files.sh" > "$setup";
    chmod +x "$setup"


    # libdir contains files that we want to encrypt
    libdir="$dir/usr/lib/postgresql/$pg_version/lib"
    mkdir -p "$libdir"

    # List all files to be encrypted and store it in the libdir as secret_files_list
    secret_files_list="$libdir/pgautofailover_secret_files.metadata"
    find "$dir" -iname "*.so" -o -iname "*.bc" -o -iname "*.control" | sed -e "s@^$dir@@g" > "$secret_files_list"

    while read -r unencrypted_file; do
        encrypt "$dir$unencrypted_file"
    done < "$secret_files_list"

done

cli_dir=debian/$CLINAME
autoctl_bin="$cli_dir/usr/bin/pg_autoctl"
cli_opt="$cli_dir/opt"
mkdir -p "$cli_opt"
mv "$autoctl_bin" "$cli_opt"
autoctl_bin="$cli_opt/pg_autoctl"

encrypt "$autoctl_bin"
# Make sure pg_autoctl is unencrypted
chmod -x "$autoctl_bin.gpg"
ls -alh "$autoctl_bin.gpg"

mkdir -p "$cli_dir/DEBIAN"
cp debian/package-cli-prerm "$cli_dir/DEBIAN/prerm"
chmod +x "$cli_dir/DEBIAN/prerm"

# remove the temporary gpg directory
rm -rf "$temp_gnupghome"
