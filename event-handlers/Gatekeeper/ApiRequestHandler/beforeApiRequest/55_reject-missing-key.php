<?php

$Endpoint = $_EVENT['request']->getEndpoint();
$Key = $_EVENT['request']->getKey();


if ($Endpoint->KeyRequired) {
    if (!$Key) {
        $realm = Gatekeeper::$authRealm;
        
        if ($Endpoint) {
            $realm .= '/';
        }

        header(sprintf('WWW-Authenticate: %s/%s/v%u', Gatekeeper::$authRealm, $Endpoint->Handle, $Endpoint->Version));
        JSON::error('gatekeeper key required for this endpoint but not provided', 401);
    }

    if (!$Key->canAccessEndpoint($Endpoint)) {
        JSON::error('provided gatekeeper key does not grant access to this endpoint', 403);
    }
}
