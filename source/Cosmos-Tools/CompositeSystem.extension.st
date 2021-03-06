Extension { #name : #CompositeSystem }

{ #category : #'*Cosmos-Tools' }
CompositeSystem >> gtInspectorSystemsIn: aCompositePresentation [

	<gtInspectorPresentationOrder: 40>
	aCompositePresentation list
		title: [ 'Subsystems' translated ];
		display: [ subsystems ];
		when: [ subsystems isNotEmpty ];
		tags: [ :system | system implementedInterfaces ]
]
