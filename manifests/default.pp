define append_if_no_such_line($file, $line, $refreshonly = 'false') {
   exec { "/bin/echo '$line' >> '$file'":
      unless      => "/bin/grep -Fxqe '$line' '$file'",
      path        => "/bin",
      refreshonly => $refreshonly,
   }
}

class must-have {
  include apt
  apt::ppa { "ppa:webupd8team/java": }

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => [ Apt::Ppa["ppa:webupd8team/java"], Package["git-core"] ],
  }

  package { ["vim", "curl", "git-core", "bash"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  package { "oracle-java7-installer":
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  # install drush to download drupal modules
  # package { 'drush':
  #   ensure => installed,
  # }  

  exec { "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd => "/home/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Package["curl"],
    before => Package["oracle-java7-installer"],
    logoutput => true,
  }

  #exec { 'solr-download-drupal-module':
  # command => 'drush dl search_api_solr --destination=/home/vagrant/search_api_solr',
  #  user => "vagrant",
  #  cwd => '/home/vagrant',
  #  creates => '/home/vagrant/search_api_solr',
  #  require => Package['drush'],
  #}

  file { "/vagrant":
    ensure => directory,
    before => Exec["solr-download-drupal-module"]
  }

  exec { 'solr-download-drupal-module':
   command => 'wget http://ftp.drupal.org/files/projects/search_api_solr-7.x-1.4.tar.gz && tar xzf search_api_solr-7.x-1.4.tar.gz',
    user => "vagrant",
    cwd => '/vagrant',
    path => "/usr/bin/:/bin/",
    creates => '/vagrant/search_api_solr',
    require => Exec["download_solr"],
  }

  $solr_schema_source = 'file:///vagrant/search_api_solr/solr-conf/4.x/schema.xml'
  $solr_config_source = 'file:///vagrant/search_api_solr/solr-conf/4.x/solrconfig.xml'  

  file { "/vagrant/solr":
    ensure => directory,
    before => Exec["download_solr"]
  }

  exec { "download_solr":
    command => "curl -L http://artfiles.org/apache.org/lucene/solr/4.6.0/solr-4.6.0.tgz | tar zx --directory=/vagrant/solr --strip-components 1",
    cwd => "/vagrant",
    user => "vagrant",
    path => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
  }

  file { "/etc/init/solr.conf":
    source => "/vagrant/scripts/etc/init/solr.conf",
    require => Exec["download_solr"]
  }

  file { "/etc/init.d/solr":
    ensure => link,
    target => "/etc/init/solr.conf",
    require => File["/etc/init/solr.conf"],
  }

  # Add Drupal config files

  file { '/vagrant/solr/example/solr/collection1/conf/schema.xml':
    source  => $solr_schema_source,
    require => Exec['solr-download-drupal-module'],
    # notify  => Service['tomcat6'],
  }
  file { '/vagrant/solr/example/solr/collection1/conf/solrconfig.xml':
    source  => $solr_config_source,
    require => Exec['solr-download-drupal-module'],
    # notify  => Service['tomcat6'],
  }  

  service { "solr":
    enable => true,
    ensure => running,
    #path => "/etc/init/solr.conf",
    provider => "upstart",
    #hasrestart => true,
    #hasstatus => true,
    require => [ File["/etc/init/solr.conf"], File["/etc/init.d/solr"], Package["oracle-java7-installer"] ],
  }
}

include must-have
