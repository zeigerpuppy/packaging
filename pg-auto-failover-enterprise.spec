%global pgmajorversion 11
%global pgpackageversion 11
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname pg-auto-failover-enterprise
%global extname pgautofailover
%global debug_package %{nil}
%global unencrypted_package "%{getenv:UNENCRYPTED_PACKAGE}"

Summary:	Auto-HA support for Citus
Name:		%{sname}%{?pkginfix}_%{pgmajorversion}
Provides:	%{sname}_%{pgmajorversion}
Conflicts:	%{sname}_%{pgmajorversion}
Version:	1.0.6
Release:	1%{dist}
License:	Proprietary
Group:		Applications/Databases
Source0:	https://github.com/citusdata/citus-ha/archive/v1.0.6.tar.gz
URL:		https://github.com/citusdata/citus-ha
BuildRequires:	postgresql%{pgmajorversion}-devel postgresql%{pgmajorversion}-server libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
This extension implements a set of functions to provide High Availability to
Postgres.

%prep
%setup -q -n %{sname}-%{version}

%build

# Flags taken from: https://liquid.microsoft.com/Web/Object/Read/ms.security/Requirements/Microsoft.Security.SystemsADM.10203#guide
SECURITY_CFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 -O2 -z noexecstack -fpic -Wl,-z,relro -Wl,-z,now -Wformat -Wformat-security -Werror=format-security"

currentgccver="$(gcc -dumpversion)"
requiredgccver="4.8.0"
if [ "$(printf '%s\n' "$requiredgccver" "$currentgccver" | sort -V | tail -n1)" = "$requiredgccver" ]; then
    if [ -z "${UNENCRYPTED_PACKAGE:-}" ]; then
        echo ERROR: At least GCC version "$requiredgccver" is needed to build Microsoft packages
        exit 1
    else
        echo WARNING: Using slower security flags because of outdated compiler
        SECURITY_CFLAGS="-fstack-protector-all -D_FORTIFY_SOURCE=2 -O2 -z noexecstack -fpic -Wl,-z,relro -Wl,-z,now -Wformat -Wformat-security -Werror=format-security"
    fi
fi

PATH=%{pginstdir}/bin:$PATH
make %{?_smp_mflags} CFLAGS="$SECURITY_CFLAGS"
%if 0%{?rhel} && 0%{?rhel} <= 6
%else
  make man
%endif


%install
PATH=%{pginstdir}/bin:$PATH
%make_install
# Install documentation with a better name:
%{__mkdir} -p %{buildroot}%{pginstdir}/doc/extension
%{__cp} README.md %{buildroot}%{pginstdir}/doc/extension/README-%{extname}.md

# install man pages
%if 0%{?rhel} && 0%{?rhel} <= 6
%else
  %{__mkdir} -p %{buildroot}/usr/share/man/man1
  %{__cp} docs/_build/man/pg_auto_failover.1 %{buildroot}/usr/share/man/man1/
  %{__cp} docs/_build/man/pg_autoctl.1 %{buildroot}/usr/share/man/man1/
  %{__mkdir} -p %{buildroot}/usr/share/man/man5
  %{__cp} docs/_build/man/pg_autoctl.5 %{buildroot}/usr/share/man/man5/
%endif

set -eu
set +x

if [ -n "${UNENCRYPTED_PACKAGE:-}" ]; then
    exit 0
fi

dir="%{buildroot}"
libdir="$dir/%{pginstdir}/lib"
mkdir -p "$libdir"

# List all files to be encrypted and store it in the libdir as secret_files_list
secret_files_list="$libdir/pgautofailover_secret_files.metadata"
find "$dir" -iname "*.so" -o -iname "*.bc" -o -iname "*.control" | sed -e "s@^$dir@@g" > "$secret_files_list"

PACKAGE_ENCRYPTION_KEY="${PACKAGE_ENCRYPTION_KEY:-}"
if [ -z "$PACKAGE_ENCRYPTION_KEY" ]; then
    echo "ERROR: The PACKAGE_ENCRYPTION_KEY environment variable needs to be set"
    echo "HINT: If trying to build packages locally, just set it to 'abc' or something"
    echo "HINT: If you're trying to build unencrypted packages you should set the UNENCRYPTED_PACKAGE environment variable"
    exit 1
fi

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

while read -r unencrypted_file; do
    encrypt "$dir$unencrypted_file"
done < "$secret_files_list"

encrypt %{buildroot}%{pginstdir}/bin/pg_autoctl
chmod -x %{buildroot}%{pginstdir}/bin/pg_autoctl.gpg

# remove the temporary gpg directory
rm -rf "$temp_gnupghome"

bindir="$dir/usr/bin"
mkdir -p "$bindir"

#------- START OF DECRYPT SCRIPT --------
# Create file used to decrypt
cat > "$bindir/pg-auto-failover-enterprise-pg-%{pgmajorversion}-setup" << EOF
#!/bin/sh

set -eu

pg_version=%{pgmajorversion}
libdir="%{pginstdir}/lib"
secret_files_list="\$libdir/pgautofailover_secret_files.metadata"

# Make sure the script is being run as root
if [ "\$(id -u)" -ne "0" ]; then
    echo "ERROR: pg-auto-failover-enterprise-pg-\$pg_version-setup needs to be run as root"
    echo "HINT: try running \"sudo pg-auto-failover-enterprise-pg-\$pg_version-setup\" instead"
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

CITUS_ACCEPT_LICENSE="\${CITUS_ACCEPT_LICENSE:-}"

interactive_license=false
while [ -z "\$CITUS_ACCEPT_LICENSE" ]; do
    interactive_license=true
    echo "Do you accept these terms? YES/NO"
    read -r CITUS_ACCEPT_LICENSE
done

case "\$CITUS_ACCEPT_LICENSE" in
    YES );;
    y|Y|Yes|yes )
        echo "ERROR: Only YES is accepted (all capital letters)"
        exit 1;
        ;;
    * )
        echo "ERROR: Terms of the software must be accepted"
        exit 1
esac

if [ \$interactive_license = false ]; then
    echo "Accepted terms by using CITUS_ACCEPT_LICENSE=YES environment variable"
fi

encryption_disclaimer_text="
Since Citus is a distributed database, data is sent over the network between
nodes. It is YOUR RESPONSIBILITY as an operator to ensure that this traffic is
secure.

Since Citus version 8.1.0 (released 2018-12-17) the traffic between the
different nodes in the cluster is encrypted for NEW installations. This is done
by using TLS with self-signed certificates. This means that this does NOT
protect against Man-In-The-Middle attacks. This only protects against passive
eavesdropping on the network.

This automatic TLS setup of self-signed certificates and TLS is NOT DONE in the
following cases:
1. The Citus clusters was originally created with a Citus version before 8.1.0.
   Even when the cluster is later upgraded to version 8.1.0 or higher. This is
   to make sure partially upgraded clusters continue to work.
2. The ssl Postgres configuration option is already set to 'on'. This indicates
   that the operator has set up their own certificates.

In these cases it is assumed the operator has set up appropriate security
themselves.

So, with the default settings Citus clusters are not safe from
Man-In-The-Middle attacks. To secure the traffic completely you need to follow
the practices outlined here:
https://docs.citusdata.com/en/stable/admin_guide/cluster_management.html#connection-management

Please confirm that you have read this and understand that you should set up
TLS yourself to send traffic between nodes securely:
YES/NO?"

CITUS_ACCEPT_ENCRYPTION_DISCLAIMER="\${CITUS_ACCEPT_ENCRYPTION_DISCLAIMER:-}"
while [ -z "\$CITUS_ACCEPT_ENCRYPTION_DISCLAIMER" ]; do
    echo "\$encryption_disclaimer_text"
    read -r CITUS_ACCEPT_ENCRYPTION_DISCLAIMER
done

case "\$CITUS_ACCEPT_ENCRYPTION_DISCLAIMER" in
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
temp_gnupghome="\$(mktemp -d)"
CITUS_LICENSE_KEY="\${CITUS_LICENSE_KEY:-}"
while [ -z "\$CITUS_LICENSE_KEY" ]; do
    echo ''
    echo 'Please enter license key:'
    read -r CITUS_LICENSE_KEY
done

# Try to decrypt the first file in the list to check if the key is correct
if ! gpg --output "/dev/null" \
        --batch --no-tty --yes --quiet \
        --passphrase "\$CITUS_LICENSE_KEY" \
        --homedir "\$temp_gnupghome" \
        --decrypt "\$(head -n 1 "\$secret_files_list").gpg" 2> /dev/null; then
    echo "ERROR: Invalid license key supplied"
    exit 1
fi

echo "License key is valid"
echo "Installing..."

decrypt() {
    path_unencrypted="\$1"
    path_encrypted="\$path_unencrypted.gpg"
    # decrypt the encrypted file
    gpg --output "\$path_unencrypted" \
        --batch --no-tty --yes --quiet \
        --passphrase "\$CITUS_LICENSE_KEY" \
        --homedir "\$temp_gnupghome" \
        --decrypt "\$path_encrypted"

    # restore permissions and ownership
    chmod --reference "\$path_encrypted" "\$path_unencrypted"
    chown --reference "\$path_encrypted" "\$path_unencrypted"
}

# Decrypt all the encrypted files
while read -r path_unencrypted; do
    decrypt "\$path_unencrypted"
done < "\$secret_files_list"

decrypt %{pginstdir}/bin/pg_autoctl
chmod +x %{pginstdir}/bin/pg_autoctl


# remove the temporary gpg directory
rm -rf "\$temp_gnupghome"
EOF

chmod +x "$bindir/pg-auto-failover-enterprise-pg-%{pgmajorversion}-setup"

cat "$bindir/pg-auto-failover-enterprise-pg-%{pgmajorversion}-setup"

%post
installation_message="
+--------------------------------------------------------------+
Please run 'sudo pg-auto-failover-enterprise-pg-%{pgmajorversion}-setup'
to complete the setup of pg_auto_failover enterprise
+--------------------------------------------------------------+
"
echo "$installation_message"


%preun
libdir="%{pginstdir}/lib"

secret_files_list="$libdir/pgautofailover_secret_files.metadata"

# Cleanup all de decrypted files since these are not managed by the package
# manager and would be left around otherwise
while read -r path_unencrypted; do
    rm -f "$path_unencrypted"
done < "$secret_files_list"

rm -f %{pginstdir}/bin/pg_autoctl

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc %{pginstdir}/doc/extension/README-%{extname}.md
%if 0%{?rhel} && 0%{?rhel} <= 6
%else
  %doc /usr/share/man/man1/pg_auto_failover.1.gz
  %doc /usr/share/man/man1/pg_autoctl.1.gz
  %doc /usr/share/man/man5/pg_autoctl.5.gz
%endif
%{pginstdir}/share/extension/%{extname}-*.sql
%if %{unencrypted_package} != ""
  %{pginstdir}/lib/%{extname}.so
  %{pginstdir}/share/extension/%{extname}.control
  %{pginstdir}/bin/pg_autoctl
  %ifarch ppc64 ppc64le
    %else
    %if %{pgmajorversion} >= 11 && %{pgmajorversion} < 90
      %if 0%{?rhel} && 0%{?rhel} <= 6
      %else
        %{pginstdir}/lib/bitcode/%{extname}*.bc
        %{pginstdir}/lib/bitcode/%{extname}/*.bc
      %endif
    %endif
  %endif
%else
  /usr/bin/pg-auto-failover-enterprise-pg-%{pgmajorversion}-setup
  %{pginstdir}/lib/pgautofailover_secret_files.metadata
  %{pginstdir}/lib/%{extname}.so.gpg
  %{pginstdir}/share/extension/%{extname}.control.gpg
  %{pginstdir}/bin/pg_autoctl.gpg
  %ifarch ppc64 ppc64le
    %else
    %if %{pgmajorversion} >= 11 && %{pgmajorversion} < 90
      %if 0%{?rhel} && 0%{?rhel} <= 6
      %else
        %{pginstdir}/lib/bitcode/%{extname}*.bc.gpg
        %{pginstdir}/lib/bitcode/%{extname}/*.bc.gpg
      %endif
    %endif
  %endif
%endif



%changelog
* Wed Feb 12 2020 - Murat Tuncer <murat.tuncer@microsoft.com> 1.0.6
- Official release for pg-auto-failover-enterprise 1.0.6

* Thu Sep 26 2019 - Murat Tuncer <murat.tuncer@microsoft.com> 1.0.5
- Official release for pg-auto-failover-enterprise 1.0.5

* Wed Jul 31 2019 - Murat Tuncer <murat.tuncer@microsoft.com> 1.0.3
- Official release for pg-auto-failover-enterprise 1.0.3

* Thu May 23 2019 - Nils Dijk <nils@citusdata.com> 1.0.2
- Official release for pg-auto-failover-enterprise 1.0.2

* Thu Apr 18 2019 - Nils Dijk <nils@citusdata.com> 2.1.0
- Official release for 2.1.0

* Fri Feb 22 2019 - Nils Dijk <nils@citusdata.com> 2.0.0
- Official release for 2.0.0

* Fri Oct 5 2018 - Burak Velioglu <velioglub@citusdata.com> 1.0.0
- Official release for 1.0.0
