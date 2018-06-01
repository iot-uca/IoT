Class {
	#name : #TriggersAPIContext,
	#superclass : #Object,
	#instVars : [
		'rootSystem'
	],
	#category : 'Cosmos-Triggers-API-Core-Model'
}

{ #category : #'instance creation' }
TriggersAPIContext class >> workingWith: aCompositeSystem [ 

	^ self new initializeWorkingWith: aCompositeSystem 
]

{ #category : #systems }
TriggersAPIContext >> actionManagementSystem [
	
	^ rootSystem systemImplementing: #ActionManagementSystemInterface
]

{ #category : #'private-parsers' }
TriggersAPIContext >> actionParser [

	^ BlockToParserAdapter
		onParsingEvaluate: [ :string | 
			self actionManagementSystem
				actionNamed: string
				ifFound: [ :action | action ]
				ifNone: [ Error signal: 'Action not found' ] ]
]

{ #category : #systems }
TriggersAPIContext >> dataManagementSystem [

	^ rootSystem systemImplementing: #DataManagementSystemInterface
]

{ #category : #'private-parsers' }
TriggersAPIContext >> dataStreamParser [

	^ BlockToParserAdapter
		onParsingEvaluate: [ :string | 
			self dataManagementSystem
				streamNamed: string
				ifFound: [ :stream | stream ]
				ifNone: [ Error signal: 'aca loco' ] ]
]

{ #category : #'initialize-release' }
TriggersAPIContext >> initializeWorkingWith: aCompositeSystem [ 

	rootSystem := aCompositeSystem 
]

{ #category : #mapping }
TriggersAPIContext >> mapToJson: anActionTrigger [

	| jsonMapping |

	jsonMapping := [ :object | 
	String
		streamContents: [ :stream | 
			(NeoJSONWriter on: stream)
				for: ActionTrigger
					do: [ :mapping | 
					mapping
						mapAccessor: #name;
						mapAccessor: #creationDateTime to: 'created_on';
						mapAccessor: #action;
						mapAccessor: #triggeringPolicy to: 'policy'.
					(mapping mapInstVar: #condition to: #conditions) valueSchema: #Bleh ];
				for: #Bleh
					customDo: [ :mapping | 
					mapping
						encoder: [ :condition | 
							| mappings |

							mappings := Dictionary new.
							mappings
								at: AndCompositeTriggeringCondition put: [ Array withAll: (condition instVarNamed: #triggerConditions) ];
								at: AlwaysTriggeringCondition put: [ Array empty ];
								at: DataStreamCurrentValueTriggeringCondition
									put: [ Array
										with:
											(OrderedDictionary new
												at: #type put: #data_stream_current_value;
												at: #data_stream put: (condition instVarNamed: #dataStream) name;
												at: #condition put: (condition instVarNamed: #condition);
												yourself) ];
								at: TimeIntervalTriggeringCondition
									put: [ Array
										with:
											(OrderedDictionary new
												at: #type put: #time_interval;
												at: #from put: (condition instVarNamed: #timeInterval) from;
												at: #to put: (condition instVarNamed: #timeInterval) to;
												yourself) ];
								yourself.
							(mappings at: condition class) value ] ];
				for: TimeIntervalTriggeringCondition
					customDo: [ :mapping | 
					mapping
						encoder: [ :condition | 
							OrderedDictionary new
								at: #type put: #time_interval;
								at: #from put: (condition instVarNamed: #timeInterval) from;
								at: #to put: (condition instVarNamed: #timeInterval) to;
								yourself ] ];
				for: DataStreamCurrentValueTriggeringCondition
					customDo: [ :mapping | 
					mapping
						encoder: [ :condition | 
							OrderedDictionary new
								at: #type put: #data_stream_current_value;
								at: #data_stream put: (condition instVarNamed: #dataStream) name;
								at: #condition put: (condition instVarNamed: #condition);
								yourself ] ];
				for: Action customDo: [ :mapping | mapping encoder: [ :action | action name ] ];
				for: PeriodicalTriggeringPolicy
					customDo: [ :mapping | 
					mapping
						encoder: [ :policy | 
							{(#type -> #periodical).
							(#time_interval -> (policy instVarNamed: #timePeriod))} asOrderedDictionary ] ];
				for: DataPointRegistrationTriggeringPolicy
					customDo: [ :mapping | 
					mapping
						encoder: [ :policy | 
							{(#type -> #on_data_point_registration).
							(#data_stream -> ((policy instVarNamed: #dataStream) instVarNamed: #name))} asOrderedDictionary ] ];
				for: ArithmeticCondition
					do: [ :mapping | 
					mapping
						mapInstVar: #arithmeticOperator to: #operator;
						mapInstVar: #value ];
				for: Measure customDo: [ :mapping | mapping encoder: [ :measure | measure printString ] ];
				for: TimeOfDay customDo: [ :mapping | mapping encoder: [ :timeOfDay | timeOfDay printString ] ];
				for: DateTime customDo: [ :mapping | mapping encoder: [ :dateTime | ISO8601DateTimeFormatter usingExtendedFormat format: dateTime ] ];
				prettyPrint: true;
				nextPut: object ] ].

	^ jsonMapping value: anActionTrigger
]

{ #category : #'private-parsing' }
TriggersAPIContext >> parse: aKey from: aDictionary with: aParser [

	^ self
		parse: aKey
		from: aDictionary
		with: aParser
		ifNotFound: [ ParsingFailed signal: ('<1s> is mandatory and must be present' expandMacrosWith: aKey) ]
]

{ #category : #'private-parsing' }
TriggersAPIContext >> parse: aKey from: aDictionary with: aParser ifNotFound: aNotFoundBlock [

	^ aDictionary
		at: aKey
		ifPresent: [ :rawData | aParser parse: rawData ]
		ifAbsent: aNotFoundBlock
]

{ #category : #parsing }
TriggersAPIContext >> parseActionFrom: aJSON [

	^ self
		parse: #action
		from: aJSON
		with: self actionParser
		ifNotFound: [ self halt ]
]

{ #category : #parsing }
TriggersAPIContext >> parseConditionFrom: aJSON [

	^ AlwaysTriggeringCondition new
]

{ #category : #parsing }
TriggersAPIContext >> parseDataStreamFrom: aJSON [

	^ self
		parse: #data_stream
		from: aJSON
		with: self dataStreamParser
		ifNotFound: [ self halt ]
]

{ #category : #parsing }
TriggersAPIContext >> parseTimeIntervalFrom: aJSON [

	^ self
		parse: #time_interval
		from: aJSON
		with: self timeIntervalParser
		ifNotFound: [ self halt ]
]

{ #category : #parsing }
TriggersAPIContext >> parseTriggeringPolicyFrom: aJSON [ 
	
	^ self parse: #policy from: aJSON with: self triggeringPolicyParser
]

{ #category : #'private-parsers' }
TriggersAPIContext >> timeIntervalParser [

	^ BlockToParserAdapter onParsingEvaluate: [ :string | TimeUnits minute with: 5 ]
]

{ #category : #systems }
TriggersAPIContext >> triggerManagementSystem [

	^ rootSystem systemImplementing: #TriggerManagementSystemInterface
]

{ #category : #'private-parsers' }
TriggersAPIContext >> triggeringPolicyParser [
	
	^  (DynamicParser determiningParserBy: #type)
		parsing: #periodical
			with: [ :json | PeriodicalTriggeringPolicy every: (self parseTimeIntervalFrom: json) ];
		parsing: #data_point_registration
			with:
				[ :json | DataPointRegistrationTriggeringPolicy on: (self parseDataStreamFrom: json) ];
		yourself.
]