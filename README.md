# DigiLys

DigiLys is a system implementation of the work process Part:
[http://www.partinfo.se/om-part/utsikter/digilys/](http://www.partinfo.se/om-part/utsikter/digilys/)

## License

Released under AGPL version 3. See `COPYING`.

The vendor assets directories (`app/assets/javascripts/vendor`, `vendor/assets`)
contain third party code that may be released under other licenses stated in the
start of each file.

## Development environment

The application is a standard Ruby on Rails application.

### Prerequisites

 * Ruby, the exact version is stated in `.ruby-version`.
    * It is recommended to use `rbenv` and `ruby-build` to manage Ruby.
 * PostgreSQL, version 9.2.
 * Bundler
 * memcached
    * Only required if running caching in development

### Bootstrapping the development environment

 * Clone this repo
 * Add a `config/database.yml` with your database configuration
 * Create a `config/app/base.private.yml` with overrides for the required values
   in `config/app/base.yml`
 * `bundle install`
 * `rake app:bootstrap app:create_admin`
 * Take a look in `db/seeds` for development seeds. Run them using
    `rails runner db/seeds/file.rb`.
 * `rails server`

### Development using Vagrant

Dependencies: Virtualbox and Vagrant

* `vagrant up`
* `vagrant ssh`
* `rake db:create db:setup`
* Follow the instructions above

#### If vagrant keeps disconnect due to timeouts
From console, run `vboxmanage list runningvms` and then `digilys_default_1465479952726_13223` replacing the last part with the ID from the first step.

## Configuration

Configuration of the application is done using YAML files in `config/app/`.
`base.yml` can be overridden using a `base.private.yml` file in the same
directory. It's also possible to add a configuration per environment, see
`config/initializers/app_config.rb`.

The different configuration options are described in `config/app/base.yml`.

### YubiKey

It is possible to enable two-factor authentication using YubiKey. You can either
use keys configured for YubiCloud, or it's possible to set up a private
authentication server. For details, see
[https://www.yubico.com/](https://www.yubico.com/)

## Deployment

Deployment is done via Capistrano.

Capistrano deploys to a server called `digilys`. To be able to deploy, you thus
need a SSH entry which aliases the host `digilys` to your server.

The deployment is currently done from the local repository, not a remote which
is the default behaviour of Capistrano. Deployment uses the currently checked
out git branch.

 * Deploying: `cap deploy deploy:migrate`
 * Managing the application server: `cap deploy:stop deploy:start`

It is also possible to deploy to a different server by defining the environment
variable `digilys_instance`, for example
`digilys_instance=digilys-test cap deploy deploy:migrate`.
