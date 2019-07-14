Class {
	#name : #WDESAbstractUniverse,
	#superclass : #WDESAbstractEntity,
	#instVars : [
		'engine',
		'scene',
		'physicsWorld',
		'gameLogic'
	],
	#category : #'WodenEngine-EntitySystem-Nodes'
}

{ #category : #'instance creation' }
WDESAbstractUniverse class >> for: anEngine [
	^ self basicNew initializeWithEngine: anEngine
]

{ #category : #sectors }
WDESAbstractUniverse >> activeSectors [
	"This method should return the set of active sectors"
	^ #()
]

{ #category : #physics }
WDESAbstractUniverse >> addEntitiesToPhysicsWorld [
	self activeSectors do: [ :sector |
		sector addedToPhysicsWorld: physicsWorld
	]
]

{ #category : #physics }
WDESAbstractUniverse >> addEntitiesToScene [
	self activeSectors do: [ :sector |
		sector addedToScene: scene
	]
]

{ #category : #'as yet unclassified' }
WDESAbstractUniverse >> buildSector: aBlock [
	| sector |
	sector := WDESSector new.
	self addChild: sector.
	aBlock value: sector.
	^ sector
]

{ #category : #model }
WDESAbstractUniverse >> createSimulationModel [
	self ensureValidEngine.
	^ (WDAESUniverseSimulationModel for: engine)
		universe: self;
		yourself
]

{ #category : #accesing }
WDESAbstractUniverse >> engine [
	^ engine
]

{ #category : #accesing }
WDESAbstractUniverse >> engine: anEngine [
	engine := anEngine.
	self engineChanged.
]

{ #category : #private }
WDESAbstractUniverse >> ensureValidEngine [
	engine ifNil: [ self engine: WDCEngine default ]
]

{ #category : #queries }
WDESAbstractUniverse >> findAnyEntityByTypeName: aTypeName [
	self typeName == aTypeName ifTrue: [ ^ self ].
	self activeSectors do: [ :child |
		(child findAnyEntityByTypeName: aTypeName) ifNotNil: [ :found | ^ found ]
	].

	^ nil
]

{ #category : #queries }
WDESAbstractUniverse >> findAnyPlayerStartPoint [
	^ (self findAnyEntityByTypeName: EntityTypeName_InfoPlayerStart)
]

{ #category : #accessing }
WDESAbstractUniverse >> gameLogic [
	^ gameLogic ifNil: [ gameLogic := WDAESGameLogic new universe: self ]
]

{ #category : #accessing }
WDESAbstractUniverse >> gameLogic: anObject [
	gameLogic := anObject
]

{ #category : #'as yet unclassified' }
WDESAbstractUniverse >> globalTransform [
	^ WMReversibleAffineTransformF identity
]

{ #category : #initialization }
WDESAbstractUniverse >> initializeWithEngine: anEngine [
	engine := anEngine.
	self initialize
]

{ #category : #accessing }
WDESAbstractUniverse >> physicsWorld [
	^ physicsWorld
]

{ #category : #accessing }
WDESAbstractUniverse >> physicsWorld: aPhysicsWorld [
	physicsWorld ifNotNil: [ self removeEntitiesFromPhysicsWorld ].
	physicsWorld := aPhysicsWorld.
	physicsWorld ifNotNil: [ self addEntitiesToPhysicsWorld ].
]

{ #category : #physics }
WDESAbstractUniverse >> removeEntitiesFromPhysicsWorld [
	self activeSectors do: [ :sector |
		sector removedFromPhysicsWorld: physicsWorld
	]
]

{ #category : #physics }
WDESAbstractUniverse >> removeEntitiesFromScene [
	self activeSectors do: [ :sector |
		sector removedFromScene: scene
	]
]

{ #category : #accessing }
WDESAbstractUniverse >> scene [
	^ scene
]

{ #category : #accessing }
WDESAbstractUniverse >> scene: anScene [
	scene ifNotNil: [ self removeEntitiesFromScene ].
	scene := anScene.
	scene ifNotNil: [ self addEntitiesToScene ].
	
]

{ #category : #simulation }
WDESAbstractUniverse >> tick: delta [
	physicsWorld ifNotNil: [ physicsWorld simulateTime: delta ].
	self activeSectors do: [ :sector | sector tick: delta ].
	gameLogic tick: delta.
]

{ #category : #accessing }
WDESAbstractUniverse >> universe [
	^ self
]