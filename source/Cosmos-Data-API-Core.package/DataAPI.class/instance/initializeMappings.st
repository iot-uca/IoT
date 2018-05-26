initialize-release
initializeMappings

	dataStreamsSnapshotsMapping := [ :object | 
	String
		streamContents: [ :stream | 
			(NeoJSONWriter on: stream)
				for: DataStream
					do: [ :mapping | 
					mapping
						mapAccessor: #name;
						mapAccessor: #currentValue to: 'current-value';
						mapAccessor: #lastUpdate to: 'last-update' ];
				for: DateTime
					customDo: [ :mapping | 
					mapping
						encoder: [ :dateTime | ISO8601DateTimeFormatter usingExtendedFormat format: dateTime ] ];
				prettyPrint: true;
				nextPut: object ] ].

	dataStreamMapping := [ :object | 
	String
		streamContents: [ :stream | 
			(NeoJSONWriter on: stream)
				for: DataStream
					do: [ :mapping | 
					mapping
						mapAccessor: #name;
						mapAccessor: #currentValue to: 'current-value';
						mapAccessor: #lastUpdate to: 'last-update';
						mapAccessor: #dataPoints to: 'data-points' ];
				for: DataPoint
					do: [ :mapping | 
					mapping
						mapAccessor: #timestamp;
						mapAccessor: #value ];
				for: DateTime
					customDo: [ :mapping | 
					mapping
						encoder: [ :dateTime | ISO8601DateTimeFormatter usingExtendedFormat format: dateTime ] ];
				prettyPrint: true;
				nextPut: object ] ]