Redmine OpenID Provider Plugin
==============================

This plugin enables Redmine to behave as an OpenID provider.

Installation and Setup
----------------------

1. Copy your plugin directory into #{RAILS_ROOT}/plugins.  
If you are downloading the plugin directly from GitHub,
you can do so by changing into your plugin directory and
issuing the following command:
> git clone https://github.com/buri17/redmine_openid_provider.git

2. Restart Redmine

Usage
-----
Use the following url as an OpenID endpoint:

[redmine url]/openid

If it doesn't work, try

[redmine url]/openid/xrds

License
-------
This plugin is licensed under Apache License Version 2.0.
