%global pgmajorversion 10
%global pgpackageversion 10
%global pginstdir /usr/pgsql-%{pgpackageversion}
%global sname topn

Summary:	Counter Based Implementation for top-n Approximation
Name:		%{sname}_%{pgmajorversion}
Version:	2.0.1.citus
Release:	1%{dist}
License:	Commercial
Group:		Applications/Databases
Source0:	https://github.com/citusdata/topn/archive/v2.0.1.tar.gz
URL:		https://github.com/citusdata/topn
BuildRequires:	postgresql%{pgmajorversion}-devel libxml2-devel
BuildRequires:	libxslt-devel openssl-devel pam-devel readline-devel
Requires:	postgresql%{pgmajorversion}-server
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
This extension is used to make approximations on top-n. It uses
JSONB objects to store and read the data frequency and provides
a chance to run real-time top-n queries on aggregated data.

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
%{pginstdir}/lib/topn.so
%{pginstdir}/share/extension/topn-*.sql
%{pginstdir}/share/extension/topn.control

%changelog
* Mon Nov 27 2017 - Marco Slot <marco@citusdata.com> 2.0.1.citus-1
- Ensure the number of elements does not exceed number_of_counters at the end of aggregation
- Fixes a character escaping issue

* Wed Nov 22 2017 - Burak Yucesoy <burak@citusdata.com> 2.0.0.citus-1
- Initial release

