%global sname citus
%global pgconfig %{pginstdir}/bin/pg_config

Summary:    PostgreSQL-based distributed RDBMS
Name:       %{sname}_%{pgmajorversion}
Version:    %{rpmversion}
Release:    %{rpmrelease}
License:    GPLv2+
Group:      Applications/Databases
Source0:    https://api.github.com/repos/citusdata/citus/tarball/%{ghtag}
URL:        https://github.com/citusdata/citus
BuildRequires:    postgresql%{pgmajorversion}-devel libxml2-devel libxslt-devel openssl-devel pam-devel readline-devel
Requires:         postgresql%{pgmajorversion}-server
Requires(post):   %{_sbindir}/update-alternatives
Requires(postun): %{_sbindir}/update-alternatives
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
CitusDB gives developers and enterprises the control, power and familiarity of
a traditional relational database with the ability to scale to 100s of
billions of events with ease.

%prep
%setup -q -n citusdata-%{sname}-%{ghsha}

%build
%configure PG_CONFIG=%{pgconfig}
make %{?_smp_mflags}

%install
%make_install

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

%files
%defattr(-,root,root,-)
%{pginstdir}/include/server/citus_config.h
%{pginstdir}/include/server/distributed/*.h
%{pginstdir}/lib/%{sname}.so
%{pginstdir}/bin/copy_to_distributed_table
%{pginstdir}/bin/csql
%{pginstdir}/share/extension/%{sname}-*.sql
%{pginstdir}/share/extension/%{sname}.control

%changelog
* Mon Mar 7 2016 - Jason Petersen <jason@citusdata.com> %{rpmversion}-%{rpmrelease}
- Initial RPM packaging for PostgreSQL RPM Repository
