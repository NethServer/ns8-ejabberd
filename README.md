# ns8-ejabberd

The chat function is implemented using ejabberd XMPP server. Enabled features are:

- LDAP based roster
- TLS
- Admin group

If you want to give admin permissions to an existing user, just add the user to the `adminsList` property (comma separated), the admins page is available at https://domain.com:5280/admin/

The users will authenticate after LDAP, the LDAP is found by the property `ldap_domain`. The users must login with a domain name (user@domain.com), this domain comes from the hostname_certificate value, the user's domain must match this value. The LDAP of Nethserver does not use the domain to authenticate users, the hostname_certificate and the ldap_domain might be different

## Public TCP ports

Services are available from the following port numbers:

- `5222` Standard port for Jabber/XMPP client connections, plain or STARTTLS.
- `5223` Standard port for Jabber client connections using the old SSL method.
- `5269` For XMPP federation. Only needed if you want to communicate with users on other servers.
- `5280` For admin interface.
- `5443` With encryption, used for admin interface, API, CAPTCHA, OAuth, Websockets and XMPP BOSH.

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/ejabberd:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "ejabberd1", "image_name": "ejabberd", "image_url": "ghcr.io/nethserver/ejabberd:latest"}

## Configure

Let's assume that the ejabberd instance is named `ejabberd1`.

Launch `configure-module`, by setting the following parameters:
- `hostname_certificate`: a fully qualified domain name for the Common Name of the TLS certificate, it will used as ejabberd virtualhost `user@domain.com`
- `ldap_domain`: a Ldap domain where to authenticate the users, it could be different than hostname_certificate. The ldap_domain is used to find an existing LDAP through LDAP proxy
- `adminsList`: Set the list (comma separated user1,user2,...) of admin users able to use the web admin page of ejabberd (https://domain.com:5280/admin/)
- `http_upload`: Allow users to upload files. (true/false)
- `mod_http_upload_quota_status`: Allow ejabberd to remove uploaded file (true/false default retention is 31 days)
- `s2s`: Enable the server-to-server (S2S) for XMPP federation (Port number: 5269). (true/false)
- `mod_mam_status`: The XEP-0313: Message Archive Management (mod_mam). (true/false)
- `shaper_normal`: Download speed limit in bytes/second for users, default is 500000
- `shaper_fast`:  Download speed limit in bytes/second for admin users, default is 1000000

Example:

    api-cli run configure-module --agent module/ejabberd1 --data - <<EOF
    {
    "hostname_certificate": "domain.com",
    "ldap_domain": "foo.com",
    "adminsList" : "admin@domain.com,administrator@domain.com",
    "http_upload": true,
    "s2s" : true,
    "shaper_normal": 500000,
    "shaper_fast": 1000000,
    "mod_http_upload_quota_status": true,
    "mod_mam_status":true
    }
    EOF

The above command will:
- start and configure the ejabberd instance

## Get the configuration
You can retrieve the configuration with

```
api-cli run get-configuration --agent module/ejabberd1 --data null | jq
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve ejabberd1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/ejabberd:latest

The tests are made using [Robot Framework](https://robotframework.org/)
