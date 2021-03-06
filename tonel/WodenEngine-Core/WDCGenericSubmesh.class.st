"
I represent a generic submesh.
"
Class {
	#name : #WDCGenericSubmesh,
	#superclass : #Object,
	#instVars : [
		'indexBuffer',
		'firstIndex',
		'indexCount',
		'primitiveType',
		'material'
	],
	#pools : [
		'AGPUConstants'
	],
	#category : #'WodenEngine-Core-Mesh'
}

{ #category : #comparing }
WDCGenericSubmesh >> = other [
	^ self class = other class and:
		[ firstIndex = other firstIndex and:
		[ indexCount = other indexCount and:
		[ material = other material and:
		[ primitiveType = other primitiveType ]]]]
]

{ #category : #'as yet unclassified' }
WDCGenericSubmesh >> engine: newEngine [
	indexBuffer ifNotNil: [ indexBuffer engine: newEngine ].
	material ifNotNil: [ material := material engineChangedTo: newEngine ]
]

{ #category : #'as yet unclassified' }
WDCGenericSubmesh >> exportModelWith: exporter [
	exporter submeshWith: [ :submeshExporter |
		indexBuffer ifNotNil: [
			submeshExporter indices: indexBuffer asIndexBufferAccessor asNativeArrayReference
		].
	
		submeshExporter
			primitiveType: primitiveType;
			firstIndex: firstIndex;
			indexCount: indexCount
	]
]

{ #category : #accessing }
WDCGenericSubmesh >> firstIndex [
	^ firstIndex
]

{ #category : #accessing }
WDCGenericSubmesh >> firstIndex: anObject [
	firstIndex := anObject
]

{ #category : #comparing }
WDCGenericSubmesh >> hash [
	^ self class hash bitXor:
		(firstIndex hash bitXor:
		(indexCount hash bitXor:
		(material hash bitXor:
		 primitiveType hash)))
]

{ #category : #accessing }
WDCGenericSubmesh >> indexBuffer [
	^ indexBuffer
]

{ #category : #accessing }
WDCGenericSubmesh >> indexBuffer: anObject [
	indexBuffer := anObject
]

{ #category : #accessing }
WDCGenericSubmesh >> indexCount [
	^ indexCount
]

{ #category : #accessing }
WDCGenericSubmesh >> indexCount: anObject [
	indexCount := anObject
]

{ #category : #accessing }
WDCGenericSubmesh >> material [
	^ material
]

{ #category : #accessing }
WDCGenericSubmesh >> material: anObject [
	material := anObject
]

{ #category : #enumerating }
WDCGenericSubmesh >> precacheResources [
	material ifNotNil: [ material precacheResources ]
]

{ #category : #accessing }
WDCGenericSubmesh >> primitiveType [
	^ primitiveType
]

{ #category : #accessing }
WDCGenericSubmesh >> primitiveType: anObject [
	primitiveType := anObject
]

{ #category : #rendering }
WDCGenericSubmesh >> renderOn: stateTracker instanceCount: instanceCount baseInstance: baseInstance baseVertex: baseVertex objectIndexBuffer: objectIndexBuffer [
	material ifNil: [ ^ self ].
	(stateTracker activateMaterial: material) ifFalse: [ ^ self].
	indexBuffer ifNotNil: [
		stateTracker useIndexBuffer: indexBuffer
	] ifNil: [ 
		objectIndexBuffer ifNotNil: [
			stateTracker useIndexBuffer: objectIndexBuffer
		].
	].
	
	stateTracker primitiveType: primitiveType.
	(indexBuffer isNotNil or: [ objectIndexBuffer isNotNil ]) ifTrue: [ 
		stateTracker drawElements: indexCount instance_count: instanceCount first_index: firstIndex base_vertex: baseVertex base_instance: baseInstance
	] ifFalse: [ 
		stateTracker
			drawArrays: indexCount instance_count: instanceCount first_vertex: baseVertex base_instance: baseInstance
	].

]
