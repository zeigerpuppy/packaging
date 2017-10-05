%global pgmajorversion 10
%global pgpackageversion 10
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname citus-analytics

Summary:	HyperLogLog extension for PostgreSQL
Name:		%{sname}_%{pgmajorversion}
Version:	1.0.0.citus
Release:	1%{dist}
License:	ASL 2.0
Group:		Applications/Databases
Source0:	https://github.com/citusdata/session_analytics/archive/v1.0.0.tar.gz
URL:		https://github.com/citusdata/session_analytics
BuildRequires:	postgresql%{pgmajorversion}-devel libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server postgresql%{pgmajorversion}-contrib
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
Analytics functions for hstore arrays.

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
%if 0%{?rhel} && 0%{?rhel} <= 6
%doc LICENSE
%else
%license LICENSE
%endif
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/session_analytics.so
%{pginstdir}/share/extension/session_analytics-*.sql
%{pginstdir}/share/extension/session_analytics.control

%changelog
* Tue Feb 21 2017 - Jason Petersen <jason@citusdata.com> 1.0.0.citus-1
- Initial release
