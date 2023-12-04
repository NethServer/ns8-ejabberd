# ns8-ejabberd

The chat function is implemented using ejabberd XMPP server. Enabled features are:

- LDAP based roster
- TLS
- Admin group

If you want to give admin permissions to an existing user, just add the user to the `adminsList` property (comma separated), the admins page is available at https://domain.com:5280/admin/

The users will authenticate after LDAP, the LDAP is found by the property `ldap_domain`. The users must login with a domain name (user@domain.com), this domain comes from the hostname value, the user's domain must match this value. The LDAP of Nethserver does not use the domain to authenticate users, the hostname and the ldap_domain might be different

## Public TCP ports

Services are available from the following port numbers:

- `5222` Standard port for Jabber/XMPP client connections, plain or STARTTLS.
- `5223` Standard port for Jabber client connections using the old SSL method.
- `5269` For XMPP federation. Only needed if you want to communicate with users on other servers.
- `5280` For admin interface.
- `5443` With encryption, used for admin interface, API, CAPTCHA, OAuth, Websockets and XMPP BOSH.

## Admin page

The ejabberd Web Admin allows to administer some parts of ejabberd using a web browser: accounts, Shared Roster Groups, manage the Mnesia database, create and restore backups, view server statistics, …
The administration is available at https://sub.domain.com:5280/admin/

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/ejabberd:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "ejabberd1", "image_name": "ejabberd", "image_url": "ghcr.io/nethserver/ejabberd:latest"}

## Configure

Let's assume that the ejabberd instance is named `ejabberd1`.

Launch `configure-module`, by setting the following parameters:
- `hostname`: a fully qualified domain name for the Common Name of the TLS certificate, it will used as ejabberd virtualhost `user@domain.com`
- `ldap_domain`: a Ldap domain where to authenticate the users, it could be different than hostname. The ldap_domain is used to find an existing LDAP through LDAP proxy
- `adminsList`: Set the list (comma separated user1,user2,...) of admin users able to use the web admin page of ejabberd (https://domain.com:5280/admin/)
- `http_upload`: Allow users to upload files. (true/false)
- `mod_http_upload_unlimited`: Keep uploaded files unlimited (true/false)
- `purge_httpd_upload_interval` : Remove older files then x days (default 30 days)
- `s2s`: Enable the server-to-server (S2S) for XMPP federation (Port number: 5269). (true/false)
- `mod_mam_status`: The XEP-0313: Message Archive Management (mod_mam). (true/false)
- `shaper_normal`: Download speed limit in bytes/second for users, default is 500000
- `shaper_fast`:  Download speed limit in bytes/second for admin users, default is 1000000
- `purge_mnesia_unlimited`: Keep old messages unlimited. (true/false)
- `purge_mnesia_interval`: Remove old messages from Mnesia older than x days
- `lets_encrypt`: Require a Let'sEncrypt valid certificate to Traefik. (true/false)

Example:

    api-cli run configure-module --agent module/ejabberd1 --data - <<EOF
    {
    "hostname": "domain.com",
    "ldap_domain": "foo.com",
    "adminsList" : "admin@domain.com,administrator@domain.com",
    "http_upload": true,
    "s2s" : true,
    "shaper_normal": 500000,
    "shaper_fast": 1000000,
    "mod_http_upload_unlimited": true,
    "purge_httpd_upload_interval": 30,
    "mod_mam_status":true,
    "purge_mnesia_unlimited": false,
    "purge_mnesia_interval": 30,
    "lets_encrypt": false,
    "webadmin": false
    }
    EOF

The above command will:
- start and configure the ejabberd instance

## Get the configuration
You can retrieve the configuration with

```
api-cli run get-configuration --agent module/ejabberd1 --data null | jq
```

## Change the hostname of Ejabberd and conserver the chat history

Users must use domain in order to login to ejabberd, the form is `user@domain.com`. The `domain.com` matches the `hostname` property set in the UI.
The `user` part must be a real user in the LDAP and the `domain.com` must be a domain where the `A` DNS record points to the IP of Ejabberd.
However if you change the hostname of ejabberd, you must adapt the `A` record of this new domain to the IP of Ejabberd and also you will loose the chat history.
The chat history is saved inside the Mnesia database with the form `user@domain.com`, therefore if you modify the domain, `user@domain.org` will be a new user in the database, you can login but you will not have a chat history for this user.

You need to modify the database manually if you want to conserve the chat history

```
# adapt to the MODULE_ID of your module
ssh ejabberd1@localhost
# dump a txt backup
podman exec -ti ejabberd bin/ejabberdctl dump /home/ejabberd/database/database.txt
# copy the txt file in your path to get a backup
podman cp ejabberd:/home/ejabberd/database/database.txt .
# sed change `domain.com` to `domain.org`
podman exec -ti ejabberd sed -i 's/domain.com/domain.org/g'  /home/ejabberd/database/database.txt
# Load the database and restart ejabberd
podman exec -ti ejabberd bin/ejabberdctl load  /home/ejabberd/database/database.txt
systemctl restart --user ejabberd
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve ejabberd1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/ejabberd:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
