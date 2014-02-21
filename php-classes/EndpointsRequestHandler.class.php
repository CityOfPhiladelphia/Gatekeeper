<?php

class EndpointsRequestHandler extends RecordsRequestHandler
{
	static public $recordClass = 'Endpoint';

    static public $accountLevelRead = 'Staff';
	static public $accountLevelComment = 'Staff';
	static public $accountLevelBrowse = 'Staff';
	static public $accountLevelWrite = 'Staff';
	static public $accountLevelAPI = 'Staff';
    
    static public function getRecordByHandle($endpointHandle)
    {
        // get version tag from next URL component
        if (!($endpointVersion = static::shiftPath()) || !preg_match('/^v.+$/', $endpointVersion)) {
			return static::throwInvalidRequestError('Endpoint version required');
		}
        
        $endpointVersion = substr($endpointVersion, 1);
        
        return Endpoint::getByWhere(array(
            'Handle' => $endpointHandle
            ,'Version' => $endpointVersion
        ));
    }
	
	static protected function applyRecordDelta(ActiveRecord $Endpoint, $data)
	{
		if (is_numeric($data['AlertNearMaxRequests'])) {
			$data['AlertNearMaxRequests'] = $data['AlertNearMaxRequests'] / 100;
		}
		
		return parent::applyRecordDelta($Endpoint, $data);
	}

    static public function handleRecordRequest(ActiveRecord $Endpoint, $action = false)
	{
		switch ($action ? $action : $action = static::shiftPath()) {			
			case 'rewrites':
				return static::handleRewritesRequest($Endpoint);
			default:
				return parent::handleRecordRequest($Endpoint, $action);
		}
	}
    
    static public function handleRewritesRequest(Endpoint $Endpoint)
    {
        switch ($_SERVER['REQUEST_METHOD']) {
            case 'GET':
                return static::respond('endpointRewrites', array(
                    'data' => $Endpoint->Rewrites
                ));
            case 'POST':
                if (!is_array($_POST['rewrites'])) {
                    return static::throwInvalidRequestError('POST method expects "rewrites" array');
                }
                
                $saved = array();
                $deleted = array();
                $invalid = array();
                
                foreach ($_POST['rewrites'] AS $key => $data) {
                    $nonEmptyData = array_filter($data);

                    if ($key == 'new') {
                        if (!count($nonEmptyData)) {
                            continue;
                        }
                        
                        $Rewrite = EndpointRewrite::create(array(
                            'Endpoint' => $Endpoint
                        ));
                    } else {
                        $Rewrite = EndpointRewrite::getByID($key);
                        
                        if ($Rewrite->EndpointID != $Endpoint->ID) {
                            return static::throwInvalidRequestError('Supplied rewrite ID does not belong to this endpoint');
                        }

                        if (!count($nonEmptyData)) {
                            $Rewrite->destroy();
                            $deleted[] = $Rewrite;
                            continue;
                        }
                    }
                    
                    if (empty($data['Priority'])) {
                        $data['Priority'] = EndpointRewrite::getFieldOptions('Priority', 'default');
                    }
                    
                    $Rewrite->setFields($data);
                    
                    if ($Rewrite->isDirty) {
                        if ($Rewrite->validate()) {
                            $Rewrite->save();
                            $saved[] = $Rewrite;
                        } else {
                            $invalid[] = $Rewrite;
                        }
                    }
                }
                
                return static::respond('endpointRewritesSaved', array(
                    'success' => count($saved) > 0
                    ,'saved' => $saved
                    ,'invalid' => $invalid
                    ,'deleted' => $deleted
                    ,'Endpoint' => $Endpoint
                ));
            default:
                return static::throwInvalidRequestError('Only GET/POST methods are supported');
        }
    }
}