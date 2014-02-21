<?php

class EndpointRewrite extends ActiveRecord
{
	// ActiveRecord configuration
	static public $tableName = 'endpoint_rewrites';
	static public $singularNoun = 'endpoint rewrite';
	static public $pluralNoun = 'endpoint rewrites';

	static public $fields = array(
		'EndpointID' => 'uint'
		,'Pattern'
		,'Replace'
        ,'Last' => array(
            'type' => 'boolean'
            ,'default' => false
        )
		,'Priority' => array(
			'type' => 'uint'
			,'default' => 100
		)
	);
	
	static public $relationships = array(
		'Endpoint' => array(
			'type' => 'one-one'
			,'class' => 'Endpoint'
		)
	);
    
	public function validate($deep = true)
	{
		parent::validate($deep);
		
		$this->_validator->validate(array(
			'field' => 'Pattern'
            ,'required' => false
			,'validator' => 'regexp'
            ,'regexp' => '/^(.).+\1[a-zA-Z]*$/'
            ,'errorMessage' => 'Pattern must include matching delimiters'
		));
        
        $this->_validator->validate(array(
			'field' => 'Priority'
			,'required' => false
			,'validator' => 'number'
            ,'min' => 0
			,'errorMessage' => 'Priority must be integer > 0'
		));
		
		return $this->finishValidation();
	}
}
