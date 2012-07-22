class jenkins {
  include jenkins::repo
  include jenkins::package
  include jenkins::service

  Class["jenkins::repo"] -> Class["jenkins::package"] -> Class["jenkins::service"]
}

class jenkins::git {
  install-jenkins-plugin { "git-plugin" :
    name => "git";
  }
}

class jenkins::service {
  case $::operatingsystem {
    centos, redhat, oel: {
      service { 'jenkins':
        ensure     => running,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => Class['jenkins::package']
      }
    }
    # Stay as a no-op to preserve previous behavior
    default: { }
  }
}

class jenkins::package {
  package {
    "jenkins" :
      ensure  => installed,
      require => Class['jenkins::repo']
  }
}

class jenkins::repo {
  case $operatingsystem {
    centos, redhat, oel: {
      include jenkins::repo::el
    }
    default: {
      include jenkins::repo::debian
    }
  }
}

class jenkins::repo::el {
  File {
    owner => 0,
    group => 0,
    mode  => 0644,
  }
  yumrepo { "Jenkins":
    name => "Jenkins",
    baseurl => "http://pkg.jenkins-ci.org/redhat",
    gpgcheck => "1",
    gpgkey => 'file:///etc/yum/jenkins-ci.org.key'
  }
  file { '/etc/yum/jenkins-ci.org.key':
    content => template("${module_name}/jenkins-ci.org.key"),
  }
  exec { 'rpm --import /etc/yum/jenkins-ci.org.key':
    path    => "/bin:/usr/bin",
    require => File['/etc/yum/jenkins-ci.org.key'],
    unless  => "rpm -q gpg-pubkey-d50582e6-4a3feef6",
  }
}

class jenkins::repo::debian {
  file {
      "/etc/apt/sources.list.d" :
          ensure => directory;

      "/etc/apt/sources.list.d/jenkins.list" :
          ensure => present,
          notify => [
                      Exec["install-key"],
                      Exec["refresh-apt"],
                    ],
          source => "puppet:///modules/jenkins/apt.list",
  }

  file {
      "/root/jenkins-ci.org.key" :
          source => "puppet:///modules/jenkins/jenkins-ci.org.key",
          ensure => present;
  }

  exec {
      "refresh-apt" :
          refreshonly => true,
          require => [
                      File["/etc/apt/sources.list.d/jenkins.list"],
                      Exec["install-key"],
                      ],
          path    => ["/usr/bin", "/usr/sbin"],
          command => "apt-get update";

      "install-key" :
          notify => Exec["refresh-apt"],
          require => [
                      File["/etc/apt/sources.list.d/jenkins.list"],
                      File["/root/jenkins-ci.org.key"],
                      ],
          # Don't install the key unless it's not already installed
          unless  => "/usr/bin/apt-key list | grep 'D50582E6'",
          command => "/usr/bin/apt-key add /root/jenkins-ci.org.key";
  }
}

define install-jenkins-plugin($name, $version=0) {
  $plugin     = "${name}.hpi"
  $plugin_parent_dir = "/var/lib/jenkins"
  $plugin_dir = "/var/lib/jenkins/plugins"

  if ($version != 0) {
    $base_url = "http://updates.jenkins-ci.org/download/plugins/${name}/${version}/"
  }
  else {
    $base_url   = "http://updates.jenkins-ci.org/latest/"
  }

  if (!defined(File["${plugin_dir}"])) {
    file {
      [$plugin_parent_dir, $plugin_dir]:
        owner  => "jenkins",
        ensure => directory;
    }
  }

  if (!defined(User["jenkins"])) {
    user {
      "jenkins" :
        ensure => present;
    }
  }

  exec {
    "download-${name}" :
      command  => "wget --no-check-certificate ${base_url}${plugin}",
      cwd      => "${plugin_dir}",
      require  => File["${plugin_dir}"],
      path     => ["/usr/bin", "/usr/sbin",],
      user     => "jenkins",
      unless   => "test -f ${plugin_dir}/${plugin}";
  }
}

# vim: ts=2 et sw=2 autoindent
