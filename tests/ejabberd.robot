*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Test Cases ***
Check if ejabberd is installed correctly
    ${output}  ${rc} =    Execute Command    add-module ${IMAGE_URL} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Check if ejabberd can be configured
    ${rc} =    Execute Command    api-cli run module/${module_id}/configure-module --data '{"hostname":"ejabberd.org","ldap_domain":"nethserver.org","adminsList":"user1@ejabberd.org,user2@ejabberd.org","http_upload":true,"s2s":true,"shaper_normal":500000,"shaper_fast":1000000,"mod_http_upload_unlimited":true,"mod_mam_status":true,"purge_mnesia_unlimited":false,"purge_mnesia_interval":30,"lets_encrypt":false,"purge_httpd_upload_interval":31,"webadmin":false}'
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if ejabberd works as expected
    ${rc} =    Execute Command    curl -k https://localhost:5280/api/status
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Check if ejabberd is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
