%global pgmajorversion 10
%global pgpackageversion 10
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname citusha

Summary:	Auto-failover for Postgres
Name:		%{sname}_%{pgmajorversion}
Version:	1.0.0.citus
Release:	1%{dist}
License:	Commercial
Group:		Applications/Databases
Source0:	https://github.com/citusdata/citus-ha/archive/v1.0.0.tar.gz
URL:		https://github.com/citusdata/citus-ha
BuildRequires:	postgresql%{pgmajorversion}-devel libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
This extension allows you to set up auto-failover for a primary/secondary
pair.

%prep
%setup -q -n %{sname}-%{version}

%build
PATH=%{pginstdir}/bin:$PATH
make %{?_smp_mflags}

%install
PATH=%{pginstdir}/bin:$PATH
%make_install
# Install documentation with a better name:
%{__mkdir} -p %{buildroot}%{pginstdir}/doc/extension
%{__cp} README.md %{buildroot}%{pginstdir}/doc/extension/README-%{sname}.md

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/citusha.so
%{pginstdir}/share/extension/citusha-*.sql
%{pginstdir}/share/extension/citusha.control
%{pginstdir}/bin/citus-ha-keeper
%{pginstdir}/bin/citus-ha-monitor
%{pginstdir}/bin/tinydns
%{pginstdir}/bin/tinydns-conf
%{pginstdir}/bin/tinydns-data
%{pginstdir}/bin/tinydns-edit
%{pginstdir}/bin/dnsip

%changelog
* Mon Apr 10 2018 - Marco Slot <marco@citusdata.com> 1.0.0.citus-1
- Initial release

