Class {
	#name : #CommandsRESTfulControllerTest,
	#superclass : #SystemBasedRESTfulControllerUserStoryTest,
	#category : #'Cosmos-API-Commands-Tests'
}

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> baseUrl [

	^ 'https://tests.cosmos.com' asZnUrl
]

{ #category : #'media types' }
CommandsRESTfulControllerTest >> commandVersion1dot0dot0MediaType [
	
	^ resourceController commandVersion1dot0dot0MediaType
]

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> identifierProvider [

	^ SequentialIdentifierProvider providing: self identifierSequence 
]

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> identifierSequence [

	^ {self turnOnLedWithHighestPriorityIndentifier.
	self turnOnLedWithLowestPriorityIdentifier.
	self turnOffLedWithMediumPriorityIdentifier.
	(UUID fromString: '4ffbff8b-9c3f-0d00-bdbd-482504a01069')}
]

{ #category : #'private - requests' }
CommandsRESTfulControllerTest >> requestToCreateCommandFrom: aJSON [

	^ self requestToPost: aJSON as: self commandVersion1dot0dot0MediaType
]

{ #category : #'private - requests' }
CommandsRESTfulControllerTest >> requestToDeleteCommandIdentifiedBy: anIdentifier [

	^ TeaRequest
		fromZnRequest: (ZnRequest delete: (self urlForResourceIdentifiedBy: anIdentifier))
		pathParams: {(#identifier -> anIdentifier)} asDictionary
]

{ #category : #'private - requests' }
CommandsRESTfulControllerTest >> requestToDequeueCommandAccepting: aMediaType [

	^ ( ZnRequest post: 'http://COSMOS_URL/commands/dequeue' ) setAccept: aMediaType
]

{ #category : #'private - requests' }
CommandsRESTfulControllerTest >> requestToGetCommandIdentifiedBy: anIdentifier accepting: aMediaType [

	^ self requestToGetResourceIdentifiedBy: anIdentifier accepting: aMediaType
]

{ #category : #'private - requests' }
CommandsRESTfulControllerTest >> requestToGetCommandsAccepting: aMediaType [

	^ self requestToGetResourcesAccepting: aMediaType
]

{ #category : #'private - requests' }
CommandsRESTfulControllerTest >> requestToGetCommandsOrderedAccoringTo: order accepting: mediaType [

	^ TeaRequest
		fromZnRequest:
			((ZnRequest get: self resourceUrl)
				setAccept: mediaType;
				yourself)
		pathParams: {(#order -> order)} asDictionary
]

{ #category : #running }
CommandsRESTfulControllerTest >> setUp [

	super setUp.

	(LEDCommandsAddOn on: rootSystem) install
]

{ #category : #running }
CommandsRESTfulControllerTest >> setUpRequirements [

	self flag: 'requireCommandManagementSystem'.

	self
		registerSubsystem: (TimeSystem using: (FixedTimeSource on: self systemDateTime));
		registerSubsystem: MetadataSystem new;
		registerSubsystem: (IdentifierSystem using: self identifierProvider);
		registerSubsystem: TimestampingSystem new;
		registerSubsystem: CommandManagementSystem new
]

{ #category : #running }
CommandsRESTfulControllerTest >> setUpResourceController [

	resourceController := CommandsRESTfulController workingWith: rootSystem.
]

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> systemDateTime [

	^ DateTime 
		date: October first , 2014 
		timeOfDay: TimeOfDay noon 
		zone: TimeZones buenosAires
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testCreateCommand [

	| response commandWithPriority |

	self assert: self commandManagementSystem commands size equals: 3.

	response := resourceController
		createCommandBasedOn:
			(self
				requestToCreateCommandFrom: '{"command":"TURN_ON_LED","priority":100}')
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response code equals: 201;
		assert: response location
			equals:
			'https://tests.cosmos.com/commands/4ffbff8b-9c3f-0d00-bdbd-482504a01069';
		assert: response contentType equals: self commandVersion1dot0dot0MediaType.

	self assert: self commandManagementSystem commands size equals: 4.
	commandWithPriority := self commandManagementSystem commands last.

	self
		assert: commandWithPriority command equals: 'TURN_ON_LED';
		assert: commandWithPriority priority equals: 100
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testDeleteCommand [

	| response |

	self assert: self commandManagementSystem commands size equals: 3.

	response := resourceController
		deleteCommandBasedOn: (self requestToDeleteCommandIdentifiedBy: self turnOffLedWithMediumPriorityIdentifier)
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response status equals: 204;
		deny: response hasEntity;
		assert: self commandManagementSystem commands size equals: 2
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testDequeueCommandEncodedAsJson [

	| response |

	response := resourceController
		nextCommandBasedOn: ( self requestToDequeueCommandAccepting: self commandVersion1dot0dot0MediaType )
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response code equals: 200;
		assert: response contentType equals: self commandVersion1dot0dot0MediaType.

	self
		assert: response contents
		equals:
			'{"command":"TURN_ON_LED","priority":100,"links":{"self":"https://tests.cosmos.com/commands/a3ad3f02-7137-0d00-ad4c-8ce2051f8f4c"}}'
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testDequeueCommandEncodedAsPlainText [

	| response |

	response := resourceController
		nextCommandBasedOn: ( self requestToDequeueCommandAccepting: self textPlain )
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response code equals: 200;
		assert: response contentType equals: ZnMimeType textPlain.

	self assert: response contents equals: 'TURN_ON_LED'
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testGetCommand [

	| response |

	response := resourceController
		getCommandBasedOn:
			( self
				requestToGetCommandIdentifiedBy: self turnOnLedWithHighestPriorityIndentifier
				accepting: self commandVersion1dot0dot0MediaType )
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response code equals: 200;
		assert: response contentType equals: self commandVersion1dot0dot0MediaType;
		assert: response entityTag equals: '"7434c0390aedccd0d9ecdaf0432beaeee244a0c0"' asETag;
		withJSONFromContentsIn: response contents
			do: [ :json | 
			self
				assert: json priority equals: 1;
				assert: json command equals: 'TURN_ON_LED';
				assert: json links self
					equals: 'https://tests.cosmos.com/commands/af1ac24c-6c37-0d00-8b39-e65c01b794dc'
			]
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testGetCommands [

	| response |

	response := resourceController
		getCommandsBasedOn: ( self requestToGetCommandsAccepting: self commandVersion1dot0dot0MediaType )
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response code equals: 200;
		assert: response contentType equals: self commandVersion1dot0dot0MediaType;
		assert: response contents
			equals:
			'{"items":[{"command":"TURN_ON_LED","priority":1,"links":{"self":"https://tests.cosmos.com/commands/af1ac24c-6c37-0d00-8b39-e65c01b794dc"}},{"command":"TURN_ON_LED","priority":100,"links":{"self":"https://tests.cosmos.com/commands/a3ad3f02-7137-0d00-ad4c-8ce2051f8f4c"}},{"command":"TURN_OFF_LED","priority":50,"links":{"self":"https://tests.cosmos.com/commands/7606aa4d-6c37-0d00-8b3a-dd4a01b794dc"}}],"links":{"self":"https://tests.cosmos.com/commands"}}'
]

{ #category : #tests }
CommandsRESTfulControllerTest >> testGetPrioritizedCommands [

	| response orderingPolicy mediaType |

	orderingPolicy := 'priority'.
	mediaType := self commandVersion1dot0dot0MediaType.

	response := resourceController
		getCommandsBasedOn: ( self requestToGetCommandsOrderedAccoringTo: orderingPolicy accepting: mediaType )
		within: self httpRequestContext.

	self
		assert: response isSuccess;
		assert: response code equals: 200;
		assert: response contentType equals: mediaType;
		assert: response contents
			equals:
			'{"items":[{"command":"TURN_ON_LED","priority":100,"links":{"self":"https://tests.cosmos.com/commands/a3ad3f02-7137-0d00-ad4c-8ce2051f8f4c"}},{"command":"TURN_OFF_LED","priority":50,"links":{"self":"https://tests.cosmos.com/commands/7606aa4d-6c37-0d00-8b3a-dd4a01b794dc"}},{"command":"TURN_ON_LED","priority":1,"links":{"self":"https://tests.cosmos.com/commands/af1ac24c-6c37-0d00-8b39-e65c01b794dc"}}],"links":{"self":"https://tests.cosmos.com/commands"}}'
]

{ #category : #'private - media types' }
CommandsRESTfulControllerTest >> textPlain [

	^ 'text/plain;charset=utf-8' asZnMimeType
]

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> turnOffLedWithMediumPriorityIdentifier [

	^ UUID fromString: '7606aa4d-6c37-0d00-8b3a-dd4a01b794dc'
]

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> turnOnLedWithHighestPriorityIndentifier [

	^ UUID fromString: 'af1ac24c-6c37-0d00-8b39-e65c01b794dc'
]

{ #category : #'private - accessing' }
CommandsRESTfulControllerTest >> turnOnLedWithLowestPriorityIdentifier [

	^ UUID fromString: 'a3ad3f02-7137-0d00-ad4c-8ce2051f8f4c'
]
