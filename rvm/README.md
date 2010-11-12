## Diaspora  rvm tools

These tools sets up a personal environment for running diaspora based on
rvm. The installation is done in two steps: the first installs
system-wide packages as root, the second user tools.


#### Synopsis

Bootstrap distribution
      % git clone 'http://github.com/diaspora/diaspora-packages.git'
      % cd diaspora-packages/rvm

Install system packages (ubuntu):
      % sudo  ./diaspora-ubuntu-setup

Install system packages (fedora):
      % sudo  ./diaspora-fedora13-setup

Install user tools and diaspora
      % ./diaspora-user-setup

Start server:
      % ~/diaspora/script/server.sh

#### Notes

The user setup basically installs rvm, ruby and diaspora for invoking user.

Any existing $HOME/diaspora dir will be moved to a backup dir if it exists
when running diaspora-user-setup

RVM home page: [http://rvm.beginrescueend.com/](http://rvm.beginrescueend.com/)
