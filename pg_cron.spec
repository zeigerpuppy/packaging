%global pgmajorversion 96
%global pgpackageversion 9.6
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname pg_cron

Summary:	Periodic job scheduler for PostgreSQL
Name:		%{sname}_%{pgmajorversion}
Version:	1.0.0
Release:	1%{dist}
License:	PostgreSQL
Group:		Applications/Databases
Source0:	https://github.com/citusdata/pg_cron/archive/v1.0.0.tar.gz
URL:		https://github.com/citusdata/pg_cron
BuildRequires:	postgresql%{pgmajorversion}-devel libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
This extension adds a periodic job scheduler to PostgreSQL to can
run many concurrent commands in the background.

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
%doc CHANGELOG.md
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/pg_cron.so
%{pginstdir}/share/extension/pg_cron-*.sql
%{pginstdir}/share/extension/pg_cron.control

%changelog
* Fri Jan 27 2017 - Marco Slot <marco@citusdata.com> 1.0.0-1.citus-1
- Use WaitLatch instead of pg_usleep when there are no tasks
* Thu Dec 15 2016 - Marco Slot <marco@citusdata.com> 1.0.0-rc.1.citus-1
- Initial 1.0 candidate
