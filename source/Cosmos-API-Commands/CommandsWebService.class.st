Class {
	#name : #CommandsWebService,
	#superclass : #Object,
	#instVars : [
		'cosmos',
		'mappingRuleSet'
	],
	#category : #'Cosmos-API-Commands'
}

{ #category : #'instance creation' }
CommandsWebService class >> workingWith: aCosmosSystem [
	
	^ self new initializeWorkingWith: aCosmosSystem
]

{ #category : #'private - systems' }
CommandsWebService >> commandManagementSystem [

	^ cosmos systemImplementing: #CommandManagementSystemInterface
]

{ #category : #API }
CommandsWebService >> createCommandBasedOn: anHttpRequest within: aContext [

	| mediaType commandWithPriority |

	mediaType := self mediaTypeOf: anHttpRequest.

	commandWithPriority := self
		decode: anHttpRequest contents
		encodedAs: mediaType
		to: #commands
		within: aContext.

	self commandManagementSystem register: commandWithPriority.

	^ ZnResponse created: (self locationOf: commandWithPriority)
]

{ #category : #'encoding and decoding' }
CommandsWebService >> decode: aJSON encodedAs: aMediaType to: aKeyRepresentingObjectType within: aContext [

	^ (mappingRuleSet ruleToDecode: aMediaType to: aKeyRepresentingObjectType)
		applyOn: aJSON
		within: aContext
]

{ #category : #API }
CommandsWebService >> deleteCommandBasedOn: anHttpRequest within: aContext [

	^ [ | identifier |

	identifier := anHttpRequest at: #identifier.

	self commandManagementSystem
		withCommandIdentifiedBy: identifier
		do: [ :commandWithPriority | 
			self commandManagementSystem deregister: commandWithPriority.
			ZnResponse noContent ] ]
		on: ObjectNotFound
		do: [ :signal | HTTPClientError signalNotFound: signal messageText ]
]

{ #category : #'encoding and decoding' }
CommandsWebService >> encode: anObject of: aKeyRepresentingObjectType to: aMediaType within: aContext [

	^ (mappingRuleSet ruleToEncode: aKeyRepresentingObjectType to: aMediaType)
		applyOn: anObject
		within: aContext
]

{ #category : #API }
CommandsWebService >> getCommandsBasedOn: anHttpRequest within: aContext [

	| mimeType encodedCommands |

	mimeType := self mediaTypeOf: anHttpRequest.

	encodedCommands := self
		encode: self commandManagementSystem commands
		of: #commands
		to: mimeType
		within: aContext.

	^ ZnResponse ok: (ZnEntity json: encodedCommands)
]

{ #category : #'private - systems' }
CommandsWebService >> identifierSystem [

	^ cosmos systemImplementing: #IdentifierSystemInterface
]

{ #category : #initialization }
CommandsWebService >> initializeWorkingWith: aCosmosSystem [

	cosmos := aCosmosSystem.
	mappingRuleSet := (ReflectiveMappingRuleSetBuilder
		for: self specification) build
]

{ #category : #'private - API' }
CommandsWebService >> locationOf: commandWithPriority [

	^ ZnUrl
		fromString:
			('localhost/<1s>'
				expandMacrosWith: (self identifierSystem identifierOf: commandWithPriority) asString36)
]

{ #category : #'private - API' }
CommandsWebService >> mediaTypeOf: aHttpRequest [

	^ ZnMimeType fromString: aHttpRequest accept
]

{ #category : #API }
CommandsWebService >> nextCommandBasedOn: anHttpRequest within: aContext [

	| mimeType encodedCommand |

	mimeType := self mediaTypeOf: anHttpRequest.

	encodedCommand := self
		encode: self commandManagementSystem nextCommand
		of: #commands
		to: mimeType
		within: aContext.

	^ ZnResponse ok: (ZnEntity with: encodedCommand type: mimeType)
]

{ #category : #specification }
CommandsWebService >> specification [

	^ CommandsWebServiceSpecification new
]