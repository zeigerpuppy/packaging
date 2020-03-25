#!/bin/bash
set -euo pipefail

PACKAGE_ENCRYPTION_KEY="${PACKAGE_ENCRYPTION_KEY:-}"
if [ -z "$PACKAGE_ENCRYPTION_KEY" ]; then
    echo "ERROR: The PACKAGE_ENCRYPTION_KEY environment variable needs to be set"
    echo "HINT: If trying to build packages locally, just set it to 'abc' or something"
    exit 1
fi


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
        sed "$pg_version_regex" "debian/$script" > "$debdir/$script";
        chmod +x "$debdir/$script"
    done


    bindir="$dir/usr/bin"
    mkdir -p "$bindir"
    setup="$bindir/citus-enterprise-pg-$pg_version-setup"
    sed "$pg_version_regex" "debian/citus-setup" > "$setup";
    chmod +x "$setup"


    # libdir contains files that we want to encrypt
    libdir="$dir/usr/lib/postgresql/$pg_version/lib"
    mkdir -p "$libdir"

    # List all files to be encrypted and store it in the libdir as secret_files_list
    secret_files_list="$libdir/citus_secret_files.metadata"
    find "$dir" -iname "*.so" -o -iname "*.bc" -o -iname "*.control" | sed -e "s@^$dir@@g" > "$secret_files_list"

    while read -r unencrypted_file; do
        path_unencrypted="$dir$unencrypted_file"
        path_encrypted="$path_unencrypted.gpg"

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
            --output "$path_encrypted" \
            "$path_unencrypted" \
            <<< "$PACKAGE_ENCRYPTION_KEY"

        # keep permissions and ownership the same, so we can restore it later
        # when decrypting
        chmod --reference "$path_unencrypted" "$path_encrypted"
        chown --reference "$path_unencrypted" "$path_encrypted"

        # remove the unencrypted file from the package
        rm "$path_unencrypted"
    done < "$secret_files_list"
done


