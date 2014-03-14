# Vagrant Solr box

Vagrant Solr box to get a Drupal Solr environment quickly up and running in a VM. This fork adds the Drupal ApacheSolr module (https://drupal.org/project/apachesolr) Solr configuration for Apache Solr 4.7.

## Running the box

1. Install [Vagrant](http://www.vagrantup.com/)
2. `git clone --recursive git@github.com:Lullabot/vagrant-drupal-solr-box.git`
3. `cd vagrant-drupal-solr-box`
4. `vagrant up`
5. Open http://localhost:8983/solr/#/ (on host)
