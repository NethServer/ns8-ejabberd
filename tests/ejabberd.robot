*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${ADMIN_USER}    admin
${ADMIN_PASSWORD}    Nethesis,1234
${SCENARIO}    install
${user_domain}    ldap.dom.test
${xmpp_host}    ejabberd.dom.test
${user_password}    Nethesis,1234

*** Keywords ***

Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${ADMIN_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${ADMIN_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Ejabberdctl
    [Arguments]    ${command}
    ${out}    ${rc} =    Execute Command    runagent -m ${module_id} podman exec ejabberd ejabberdctl ${command}
    ...    return_rc=True
    RETURN    ${out}    ${rc}

Ejabberd is started
    ${out}    ${rc} =    Ejabberdctl    status
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${out}    status: started

LDAP users can authenticate
    ${out}    ${rc} =    Ejabberdctl    check_password xmpp1 ${xmpp_host} '${user_password}'
    Should Be Equal As Integers    ${rc}    0    xmpp1 cannot log in with its LDAP password
    ${out}    ${rc} =    Ejabberdctl    check_password xmpp1 ${xmpp_host} wrong-password
    Should Be Equal As Integers    ${rc}    1    xmpp1 logs in with a wrong password

xmpp2 has one offline message
    ${out}    ${rc} =    Ejabberdctl    get_offline_count xmpp2 ${xmpp_host}
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal As Integers    ${out}    1

*** Test Cases ***

Configure the LDAP user domain
    ${response} =    Run task    cluster/add-internal-provider    {"image":"openldap","node":1}
    Set Suite Variable    ${mid_ldap}    ${response['module_id']}
    Run task    module/${mid_ldap}/configure-module    {"domain":"${user_domain}","admuser":"admin","admpass":"${user_password}","provision":"new-domain"}
    Run task    module/${mid_ldap}/add-user    {"user":"xmpp1","display_name":"XMPP One","password":"${user_password}"}
    Run task    module/${mid_ldap}/add-user    {"user":"xmpp2","display_name":"XMPP Two","password":"${user_password}"}

Check if ejabberd is installed correctly
    # The update scenario starts from the NS8 stable release, then upgrades it below
    ${image} =    Set Variable If    '${SCENARIO}' == 'update'    ejabberd    ${IMAGE_URL}
    ${output}  ${rc} =    Execute Command    add-module ${image} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Take screenshots
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True
    Login to cluster-admin
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}
    Wait For Elements State    iframe >>> h2 >> text="Status"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/1._Status.png
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}?page=settings
    Wait For Elements State    iframe >>> h2 >> text="Settings"    visible    timeout=10s
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/2._Settings.png
    Close Browser

Check if ejabberd can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"hostname":"${xmpp_host}","ldap_domain":"${user_domain}","adminsList":"xmpp1@${xmpp_host}","http_upload":true,"s2s":true,"shaper_normal":500000,"shaper_fast":1000000,"mod_http_upload_unlimited":true,"mod_mam_status":true,"purge_mnesia_unlimited":false,"purge_mnesia_interval":30,"lets_encrypt":false,"purge_httpd_upload_interval":31,"webadmin":false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if ejabberd works as expected
    Wait Until Keyword Succeeds    30 times    5 seconds    Ejabberd is started

Check LDAP users can authenticate
    LDAP users can authenticate

Send a message to an offline user
    ${out}    ${rc} =    Ejabberdctl    send_message chat xmpp1@${xmpp_host} xmpp2@${xmpp_host} "" "message kept across the update"
    Should Be Equal As Integers    ${rc}    0
    xmpp2 has one offline message

Update ejabberd to the image under test
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    ${rc} =    Execute Command
    ...    api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check ejabberd works after the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    Wait Until Keyword Succeeds    30 times    5 seconds    Ejabberd is started
    LDAP users can authenticate

Check the configuration survives the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    ${config} =    Run task    module/${module_id}/get-configuration    {}
    Should Be Equal    ${config['hostname']}    ${xmpp_host}
    Should Be Equal    ${config['ldap_domain']}    ${user_domain}
    Should Be Equal    ${config['adminsList']}    xmpp1@${xmpp_host}

Check the offline message survives the update
    Skip If    '${SCENARIO}' != 'update'    scenario is ${SCENARIO}, nothing to update
    xmpp2 has one offline message

Check if ejabberd is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Remove the LDAP user domain
    Run task    cluster/remove-internal-domain    {"domain":"${user_domain}"}
