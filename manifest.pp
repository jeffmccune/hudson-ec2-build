node default {

  # java apps (sun SDK)
  if ($operatingsystem == "Fedora" or $operatingsystem == "CentOS" ) {
    exec {
      "epel":
        command => "/bin/rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-3.noarch.rpm",
        unless  => "/bin/rpm -qa | /bin/grep epel-release-5-3",
    }
  }


   $java_packages = $operatingsystem ? {
        Fedora  => "java-1.6.0-openjdk",
        CentOS  => "java-1.6.0-openjdk",
        Ubuntu  => "openjdk-6-jre-headless",
        Debian  => "openjdk-6-jre-headless",
        Solaris => "SUNWj6rt",
   }

  package {
    $java_packages:
      ensure => installed,
  }

  $default_packages = $operatingsystem ? {
    Solaris => [ "SUNWgcc", "SUNWgmake", "SUNWgnu-automake-110", "SUNWrrdtool", "SUNWmysql5",   "SUNWpostgr-83-server" ],
    default => [ "gcc",     "make",      "automake",             "rrdtool",     "mysql-server", "postgresql" ],
  }


  package {
    $default_packages:
      ensure => present,
  }

  include rubygems
  include git
  include users

  include hudson


}


class rubygems {

  package {
    "ruby_dev":
      name => $operatingsystem ? {
         Fedora  => [ "ruby-devel", "postgresql-devel",   "mysql-devel",        "sqlite",  "sqlite-devel",   "rrdtool-devel", "openldap-devel" ],
         CentOS  => [ "ruby-devel", "postgresql-devel",   "mysql-devel",        "sqlite",  "sqlite-devel",   "rrdtool-devel", "openldap-devel" ],
         Ubuntu  => [ "ruby-dev",   "libpq-dev",          "libmysqlclient-dev", "sqlite3", "libsqlite3-dev", "librrd-dev",    "libldap2-dev" ],
         Debian  => [ "ruby-dev",   "libpq-dev",          "libmysqlclient-dev", "sqlite3", "libsqlite3-dev", "librrd-dev",    "libldap2-dev" ],
      },
      ensure => present,
  }

  # We need a specific version of rspec
  package {
    "rspec":
      provider => "gem",
      ensure   => "1.2.2",
      require  => [
        Package["rake"],
      ],
      options  => "--no-ri --no-rdoc",
  }

  # Github gems TODO use gemcutter
  package {
    "relevance-rcov":
      provider => "gem",
      source   => "http://gems.github.com",
      require  => [
        Package["rake"],
      ],
      options  => "--no-ri --no-rdoc",
  }

  package {
    "rake":
      provider => "gem",
      options  => "--no-ri --no-rdoc",
      require  => Package["ruby_dev"],
  }

  package {
    [
      "mysql",
      "postgres",
      "sqlite3-ruby",
      #"RubyRRDtool",
      "ruby-ldap",
      "mongrel",
      "ci_reporter",
      "mocha",
      "hoe",
      "rails",
      "cucumber",
      "json",
      "stomp",
      "daemons",
      "test-unit",
    ]:
      provider => "gem",
      ensure   => present,
      options   => "--no-ri --no-rdoc",
      require  => Package["ruby_dev"],
  }
}

class users {

  user {
    [
      "hudson",
      "puppet",
    ]:
      groups => "mail",
  }

  file {
    "/home/hudson/.puppet":
      owner   => "hudson",
      group   => "hudson",
      ensure  => directory,
      require => File["/home/hudson"],
  }

  file {
    "/home/hudson":
      owner   => "hudson",
      group   => "hudson",
      ensure  => directory,
      require => User["hudson"],
  }

  file {
    "/home/puppet":
      owner   => "hudson",
      group   => "puppet",
      ensure  => directory,
      require => User["puppet"],
  }


}

class git {

  $git_package = $operatingsystem ? {
       Fedora  => [ "git" ],
       CentOS  => [ "git" ],
       Ubuntu  => [ "git-core" ],
       Debian  => [ "git-core" ],
       Solaris => [ "SUNWgit" ],
  }

  package {
    "git":
      name   => $git_package,
      ensure => installed,
  }

  exec {
    "setup_git":
      command => "/usr/bin/git config --global user.email 'hudson@reductivelabs.com'; /usr/bin/git config --global user.name 'Hudson User'",
      require => Package["git"],
  }
}


class hudson {

    exec {
      "get_hudson":
        command => "/usr/bin/wget -O /home/hudson/slave.jar http://beaker.inodes.org:8080/jnlpJars/slave.jar",
        require => File["/home/hudson"],
    }


}
