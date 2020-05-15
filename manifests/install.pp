# == Class: traefik::install
#
#  Fetches and installs the traefik binary
#
class traefik::install {
  if ! defined(Package['wget']) {
    package { 'wget': ensure => installed }
  }

  $install_path = "/opt/${traefik::package_name}"
  file { $install_path:
    ensure => 'directory',
    mode   => '0755',
  }

  if $traefik::version =~ /^1/ {
    exec { "${traefik::package_name}-${traefik::version}":
      command => "wget --no-check-certificate --output-document=/opt/${traefik::package_name}/${traefik::package_name}-${traefik::version} ${traefik::download_url_base}v${traefik::version}/${traefik::download_package_name}",
      creates => "${install_path}/${traefik::package_name}-${traefik::version}",
      require => [ File[$install_path], Package['wget'] ],
      path    => '/usr/bin',
    }

    file {"${install_path}/${traefik::package_name}":
      ensure  => link,
      target  => "${install_path}/${traefik::package_name}-${traefik::version}",
      require => Exec["${traefik::package_name}-${traefik::version}"],
    }

    file {"${install_path}/${traefik::package_name}-${traefik::version}":
      mode    => '0755',
      require => Exec["${traefik::package_name}-${traefik::version}"],
    }
  } else {
    include '::archive'
    if $facts['os']['family'] != 'windows' {
      Archive {
        provider => 'wget',
        require  => Package['wget'],
      }
    }

    case $facts['os']['hardware'] {
      'x86_64': { $hardware_suffix = 'amd64' }
      default: { $hardware_suffix = $facts['os']['hardware'] }
    }

    $archive_name = "${traefik::package_name}_v${traefik::version}_${facts['kernel'].downcase}_${hardware_suffix}.tar.gz"
    $archive_source = "${traefik::download_url_base}v${traefik::version}/${archive_name}"

    archive { "${install_path}/${archive_name}":
      source       => $archive_source,
      extract      => true,
      extract_path => $install_path,
      creates      => "${install_path}/${traefik::package_name}",
      cleanup      => true,
      require      => File[$install_path],
    }
    -> file { "${install_path}/${traefik::package_name}":
      mode => '0755',
    }
  }
}
