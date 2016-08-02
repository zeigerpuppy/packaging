%global pgmajorversion 95
%global pgpackageversion 9.5
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname citus-enterprise

Summary:	PostgreSQL-based distributed RDBMS
Name:		%{sname}_%{pgmajorversion}
Version:	5.2.0
Release:	0.1.rc.1%{dist}
License:	AGPLv3
Group:		Applications/Databases
Source0:	https://github.com/citusdata/citus-enterprise/archive/v5.2.0-rc.1.tar.gz
URL:		https://github.com/citusdata/citus-enterprise
BuildRequires:	postgresql%{pgmajorversion}-devel libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server
Conflicts:	citus_%{pgmajorversion}
Requires(post):	%{_sbindir}/update-alternatives
Requires(postun):	%{_sbindir}/update-alternatives
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
Citus horizontally scales PostgreSQL across commodity servers
using sharding and replication. Its query engine parallelizes
incoming SQL queries across these servers to enable real-time
responses on large datasets.

Citus extends the underlying database rather than forking it,
which gives developers and enterprises the power and familiarity
of a traditional relational database. As an extension, Citus
supports new PostgreSQL releases, allowing users to benefit from
new features while maintaining compatibility with existing
PostgreSQL tools. Note that Citus supports many (but not all) SQL
commands.

%prep
%setup -q -n %{sname}-%{version}

%build
%configure PG_CONFIG=%{pginstdir}/bin/pg_config
make %{?_smp_mflags}

%install
%make_install
# Install documentation with a better name:
%{__mkdir} -p %{buildroot}%{pginstdir}/doc/extension
%{__cp} README.md %{buildroot}%{pginstdir}/doc/extension/README-%{sname}.md

%clean
%{__rm} -rf %{buildroot}

%post
%{_sbindir}/update-alternatives --install %{_bindir}/csql \
    %{sname}-csql %{pginstdir}/bin/csql %{pgmajorversion}0
%{_sbindir}/update-alternatives --install %{_bindir}/copy_to_distributed_table \
    %{sname}-copy_to_distributed_table %{pginstdir}/bin/copy_to_distributed_table %{pgmajorversion}0

%postun
if [ $1 -eq 0 ] ; then
    %{_sbindir}/update-alternatives --remove %{sname}-csql \
	%{pginstdir}/bin/csql
    %{_sbindir}/update-alternatives --remove %{sname}-copy_to_distributed_table \
	%{pginstdir}/bin/copy_to_distributed_table
fi

%triggerpostun -- citus_%{pgmajorversion}
%{_sbindir}/update-alternatives --install %{_bindir}/csql \
    %{sname}-csql %{pginstdir}/bin/csql %{pgmajorversion}0
%{_sbindir}/update-alternatives --install %{_bindir}/copy_to_distributed_table \
    %{sname}-copy_to_distributed_table %{pginstdir}/bin/copy_to_distributed_table %{pgmajorversion}0

%files
%defattr(-,root,root,-)
%doc CHANGELOG.md
%if 0%{?rhel} && 0%{?rhel} <= 6
%doc LICENSE
%else
%license LICENSE
%endif
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/include/server/citus_config.h
%{pginstdir}/include/server/distributed/*.h
%{pginstdir}/lib/citus.so
%{pginstdir}/bin/copy_to_distributed_table
%{pginstdir}/bin/csql
%{pginstdir}/share/extension/citus-*.sql
%{pginstdir}/share/extension/citus.control

%changelog
* Mon Aug 1 2016 - Jason Petersen <jason@citusdata.com> 5.2.0-0.1.rc.1
- Release candidate for 5.2.

* Fri Jun 17 2016 - Jason Petersen <jason@citusdata.com> 5.1.1-1
- Update to Citus Enterprise 5.1.1

* Tue May 17 2016 - Jason Petersen <jason@citusdata.com> 5.1.0-1
- Update to Citus Enterprise 5.1.0

* Tue May 10 2016 - Jason Petersen <jason@citusdata.com> 5.1.0-0.1.rc.1
- Release candidate for 5.1.
