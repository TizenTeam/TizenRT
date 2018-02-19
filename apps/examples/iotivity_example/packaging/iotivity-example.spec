Name:           iotivity-example
Version:        0.0.0
Release:        0
License:        Apache-2.0
Summary:        Very minimalist example of IoTivity resource
Url:            http://github.com/TizenTeam/iotivity-example
Group:          System/Libraries
#X-Vc-Url:      http://github.com/TizenTeam/iotivity-example
Group:          Contrib

%if ! 0%{?license:0}
%define license %doc
%endif

Source:         %{name}-%{version}.tar.gz
BuildRequires:  make
BuildRequires:  fdupes
BuildRequires:  pkgconfig(iotivity)
BuildRequires:  boost-devel
BuildRequires:  pkgconfig(dlog)
BuildRequires:  systemd
Requires:  iotivity


%description
Mimimal client/server application,
that share an IoTivity resource.

%prep
%setup -q

%build

%__make %{?_smp_mflags} \
    name=%{name} \
    PLATFORM=TIZEN \
    #eol

%install
%__make install \
    DESTDIR=%{buildroot}/ \
    name=%{name} \
    PLATFORM=TIZEN \
    #eol

make %{name}.service

install -d %{buildroot}%{_unitdir}

install extra/iotivity-example.service \
  %{buildroot}%{_unitdir}/%{name}.service

%install_service network.target.wants %{name}.service


%fdupes %{buildroot}

%post -p /sbin/ldconfig

%postun -p /sbin/ldconfig


%files
%defattr(-,root,root)
%license LICENSE
/opt/%{name}/*
%{_unitdir}/%{name}.service
%{_unitdir}/network.target.wants/%{name}.service
