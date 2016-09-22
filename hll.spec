%global pgmajorversion 95
%global pgpackageversion 9.5
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname hll

Summary:	HyperLogLog extension for PostgreSQL
Name:		%{sname}_%{pgmajorversion}
Version:	2.10.1.citus
Release:	1%{dist}
License:	ASL 2.0
Group:		Applications/Databases
Source0:	https://github.com/citusdata/postgresql-hll/archive/v2.10.1.tar.gz
URL:		https://github.com/citusdata/postgresql-hll
BuildRequires:	postgresql%{pgmajorversion}-devel libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
HyperLogLog extension for PostgreSQL.

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
%{__cp} README.markdown %{buildroot}%{pginstdir}/doc/extension/README-%{sname}.md

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc CHANGELOG.markdown
%if 0%{?rhel} && 0%{?rhel} <= 6
%doc LICENSE
%else
%license LICENSE
%endif
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/hll.so
%{pginstdir}/share/extension/hll-*.sql
%{pginstdir}/share/extension/hll.control

%changelog
* Thu Sep 22 2016 - Jason Petersen <jason@citusdata.com> 2.10.1.citus-1
- First Citus-packaged release

* Fri Jan 10 2014 Timon Karnezos <timon.karnezos@gmail.com> - 2.10.0-0
- added binary IO type for hll

* Mon Dec 16 2013 Timon Karnezos <timon.karnezos@gmail.com> - 2.9.0-0
- bitstream_pack fixed to write one byte at a time to avoid writing to unallocated memory

* Tue Jul 16 2013 Timon Karnezos <timon.karnezos@gmail.com> - 2.8.0-0
- hll_add_agg now returns hll_empty on input of an empty set

* Wed Jun 12 2013 Timon Karnezos <timon.karnezos@gmail.com> - 2.7.1-0
- Build fixes for OS X and Debian.
- Documentation fixes.
- Small changes to test format to improve stability across psql versions.

* Tue Dec 11 2012 Ken Sedgwick <ken@bonsai.com> - 2.7-0
- Initial version.
