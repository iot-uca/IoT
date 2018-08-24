Class {
	#name : #MappingRuleSetBuilder,
	#superclass : #Object,
	#instVars : [
		'decodingRules',
		'encodingRules'
	],
	#category : #'Cosmos-API-Model'
}

{ #category : #managing }
MappingRuleSetBuilder >> add: aReader asDecoderFor: aMediaType within: aKeyRepresentingScope [

	| decodingRule |

	self assertDecoderNotAlreadyRegisteredFor: aMediaType within: aKeyRepresentingScope.

	decodingRule := MappingRule
		applying: aReader
		for: aMediaType
		within: aKeyRepresentingScope.

	decodingRules add: decodingRule
]

{ #category : #managing }
MappingRuleSetBuilder >> add: aReader asDefaultDecoderFor: aMediaType within: aKeyRepresentingScope [

	| decodingRule |

	self assertDecoderNotAlreadyRegisteredFor: aMediaType within: aKeyRepresentingScope.

	decodingRule := MappingRule
		applying: aReader
		for: aMediaType
		within: aKeyRepresentingScope.

	decodingRule beDefault.
	
	decodingRules add: decodingRule
]

{ #category : #managing }
MappingRuleSetBuilder >> add: aWriter asDefaultEncoderFor: aMediaType within: aKeyRepresentingScope [

	| encodingRule |

	encodingRule := MappingRule
		applying: aWriter
		for: aMediaType
		within: aKeyRepresentingScope.
		
	encodingRule beDefault.

	encodingRules
		detect: [ :rule | rule mediaType = aMediaType and: [ rule scope = aKeyRepresentingScope ] ]
		ifFound:
			[ :foundRule | ConflictingObjectFound signal: 'Encoder for that MIME type already registered' ]
		ifNone: [ encodingRules add: encodingRule ]
]

{ #category : #managing }
MappingRuleSetBuilder >> add: aWriter asEncoderFor: aMediaType within: aKeyRepresentingScope [

	| mappingRule |

	mappingRule := MappingRule
		applying: aWriter
		for: aMediaType
		within: aKeyRepresentingScope.

	encodingRules
		detect: [ :rule | rule mediaType = aMediaType and: [ rule scope = aKeyRepresentingScope ] ]
		ifFound:
			[ :foundRule | ConflictingObjectFound signal: 'Encoder for that MIME type already registered' ]
		ifNone: [ encodingRules add: mappingRule ]
]

{ #category : #'private - preconditions' }
MappingRuleSetBuilder >> assertDecoderNotAlreadyRegisteredFor: aMediaType within: aKeyRepresentingScope [

	AssertionCheckerBuilder new
		raising: ConflictingObjectFound;
		checking: [ :asserter | 
			asserter
				enforce: [ decodingRules
						noneSatisfy:
							[ :rule | rule mediaType = aMediaType and: [ rule scope = aKeyRepresentingScope ] ] ]
				because: 'Decoder for that MIME type already registered' ];
		buildAndCheck
]

{ #category : #managing }
MappingRuleSetBuilder >> build [

	AssertionCheckerBuilder new
		checking: [ :asserter | 
			asserter
				enforce: [ (decodingRules groupedBy: #scope) values
						allSatisfy: [ :rules | (rules count: [ :rule | rule isDefault ]) = 1 ] ]
				because: 'You must provide a default decoder for each scope' ];
		buildAndCheck.

	AssertionCheckerBuilder new
		checking: [ :asserter | 
			asserter
				enforce: [ (encodingRules groupedBy: #scope) values
						allSatisfy: [ :rules | (rules count: [ :rule | rule isDefault ]) = 1 ] ]
				because: 'You must provide a default decoder for each scope' ];
		buildAndCheck.



	^ MappingRuleSet consistingOf: encodingRules and: decodingRules
]

{ #category : #initialization }
MappingRuleSetBuilder >> initialize [

	encodingRules := OrderedCollection new.
	decodingRules := OrderedCollection new
]