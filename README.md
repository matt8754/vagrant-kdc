# Setup

First, we need to add the fedora/23-cloud-base box.

```sh
vagrant box add fedora/23-cloud-base
```

The vagrant `hostsupdater` plugin is used to modify local `/etc/hosts`.

```sh
vagrant plugin install vagrant-hostsupdater
```

The vagrant `cachier` plugin is supported to speed up installation of yum
packages.

```sh
vagrant plugin install vagrant-cachier
```

# Instructions

We use `EXAMPLE.COM` as the realm through-out. The FORWARDER in config/server_config/config.sh
needs to be updated with a valid DNS server.

Spin up the KDC server `ipaserver`. This host also acts as DNS server
and NTP server for the `client`.

```sh
vagrant up ipaserver
```

Next, start the `client`. The setup script connects to the KDC, adds the host
to the realm, and generates a keytab for the service `HTTP/client.example.com`
into the file `/vagrant/http.keytab`.

```sh
vagrant up client
```

## (Optional) add HTTP/client.example.com to system keytab

You can also add the service principal to the system keytab at /etc/krb5.keytab.
This is not recommended in general, because it requires the service to have
permission to read the system keytab, which is usually root-only.

```sh
[vagrant@client ~]$ sudo ktutil
ktutil:  read_kt /etc/krb5.keytab
ktutil:  read_kt /vagrant/http.keytab
ktutil:  list
slot KVNO Principal
---- ---- ---------------------------------------------------------------------
   1    1      host/client.example.com@EXAMPLE.COM
   2    1      host/client.example.com@EXAMPLE.COM
   3    1      host/client.example.com@EXAMPLE.COM
   4    1      host/client.example.com@EXAMPLE.COM
   5    1      HTTP/client.example.com@EXAMPLE.COM
   6    1      HTTP/client.example.com@EXAMPLE.COM
   7    1      HTTP/client.example.com@EXAMPLE.COM
   8    1      HTTP/client.example.com@EXAMPLE.COM
ktutil:  write_kt /etc/krb5.keytab
```

To check if the principal was written correctly, try authenticating as the
service using the system keytab:

```sh
[vagrant@client ~]$ sudo kinit -kt /etc/krb5.keytab HTTP/client.example.com
```

# Setting up your machine with Kerberos

If you want to access the Kerberized services on the VMs from your host
machine, you must configure your host machine to authenticate against the KDC:

`/etc/krb5.conf`
```
[realms]
EXAMPLE.COM = {
  kdc = ipaserver.example.com:88
  default_domain = example.com
}

[domain_realm]
.example.com = EXAMPLE.COM
example.com = EXAMPLE.COM

[libdefaults]
default_realm = EXAMPLE.COM
```

You will now be able to execute `kinit admin` (password: `aaaAAA111`) to authenticate with the KDC.
Once you have done so, you can open `http://ipaserver.example.com` in a browser
to administrate the server. You should be authenticated automatically - if not, you might need to [setup your browser](#BrowserSetup)

## Browser setup

### Safari

no setup required!

### Chrome

See: http://www.chromium.org/developers/design-documents/http-authentication
https://www.chromium.org/administrators

The `AuthServerWhitelist` policy must be set to `*.example.com` - this will
allow Chrome to present credentials to any website ending with `example.com`.

I have not verified, but `DisableAuthNegotiateCnameLookup` may also be required
- this will prevent Chrome from canonicalizing the hostname before generating a
service name.

These can be set on OS X in the following way:

```
defaults write com.google.Chrome AuthServerWhitelist "*.example.com"

# if your DNS is not set up (e.g. you are using /etc/hosts), you may also need:
defaults write com.google.Chrome DisableAuthNegotiateCnameLookup -bool yes
```

### Firefox

* Navigate to about:config
* Search for "negotiate"
* For `network.negotiate-auth.trusted-uris` set the value to `.example.com`

### IE (untested)

* Internet Options > Tools > Advanced Tab
* Within Security section, select “Enable Integrated Windows Authentication”
* Restart browser

# Credits

Based on the gist from: http://www.roguelynn.com/words/setting-up-a-kerberos-test-environment/
