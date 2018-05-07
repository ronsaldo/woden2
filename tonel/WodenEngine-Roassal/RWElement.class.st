Class {
	#name : #RWElement,
	#superclass : #RWAnnounceableObject,
	#instVars : [
		'shape',
		'model',
		'sceneNode',
		'renderable',
		'mass',
		'rigidBody',
		'connectedEdges',
		'view',
		'behaviors'
	],
	#category : 'WodenEngine-Roassal-Core'
}

{ #category : #interaction }
RWElement >> @ anInteractionClassOrInstance [
	"Add an interaction to the node"
	
	self addInteraction: anInteractionClassOrInstance
]

{ #category : #adding }
RWElement >> addBehavior: aBehavior [
	behaviors add: aBehavior.
	aBehavior addedInElement: self.
]

{ #category : #adding }
RWElement >> addConnectedEdge: anEdge [
	[  anEdge class == RWEdge ] assert.
	self connectedEdges add: anEdge
]

{ #category : #interaction }
RWElement >> addInteraction: anInteraction [
	anInteraction initializeElement: self
]

{ #category : #adding }
RWElement >> addedIn: aView [
	renderable := shape buildRenderableFor: self view: aView.
	sceneNode isInstance ifFalse: [
		aView validScene add: sceneNode.
	].

	self buildRigidBodyForView: aView.

	view := aView
]

{ #category : #interaction }
RWElement >> announce: eventOrClassEvent [
	announcer announce: eventOrClassEvent
]

{ #category : #converting }
RWElement >> asSceneNode [
	^ sceneNode
]

{ #category : #computing }
RWElement >> boundingBox [
	self flag: 'TODO: Transform properly the bounding box.'.
	^ self localBoundingBox translatedBy: sceneNode transform translation
]

{ #category : #physics }
RWElement >> buildRigidBodyForView: aView [
	| collisionShape |
	mass ifNil: [ ^ self ].
	collisionShape := shape buildCollisionShapeFor: self.
	rigidBody := WTRigidBody new
					sceneNode: sceneNode;
					mass: mass;
					shape: collisionShape.
	aView addRigidBody: rigidBody
]

{ #category : #updating }
RWElement >> changed [
	shape changedElement: self sceneNode: sceneNode renderable: renderable.
	sceneNode stateChanged
]

{ #category : #'trachel compatibility' }
RWElement >> color [
	^ self shape colorFor: self
]

{ #category : #'trachel compatibility' }
RWElement >> color: aColor [
	^ self shape color: aColor
]

{ #category : #accessing }
RWElement >> connectedEdges [
	"Return the list of connected egdes (i.e., incoming and outgoing edges)"
	connectedEdges ifNil: [ connectedEdges := RWGroup new ].
	^ connectedEdges
]

{ #category : #initialization }
RWElement >> createSceneNode [
	^ WTSSpatialObject new
]

{ #category : #accessing }
RWElement >> depth [
	^ shape depthFor: self
]

{ #category : #accessing }
RWElement >> extent [
	^ WMVector3F x: self width asFloat y: self height asFloat z: self depth asFloat
]

{ #category : #accessing }
RWElement >> height [
	^ shape heightFor: self
]

{ #category : #initialization }
RWElement >> initialize [
	super initialize.
	behaviors := OrderedCollection new.
	sceneNode := self createSceneNode.
	shape := RWNullShape new.

]

{ #category : #testing }
RWElement >> isConnectedTo: anElement [
	connectedEdges ifNil: [ ^ false ].
	^ connectedEdges anySatisfy: [ :edge | (edge from == anElement) or: [ edge to == anElement ] ]
]

{ #category : #testing }
RWElement >> isDirectlyConnectedTo: anElement [
	connectedEdges ifNil: [ ^ false ].
	^ connectedEdges anySatisfy: [ :edge | edge to == anElement ]
]

{ #category : #testing }
RWElement >> isEdge [
	^ false
]

{ #category : #testing }
RWElement >> isElement [
	^ true
]

{ #category : #computing }
RWElement >> localBoundingBox [
	^ renderable ifNil: [ shape boundingBoxFor: self ] ifNotNil: [ renderable boundingBox ]
]

{ #category : #orientation }
RWElement >> lookDown [
	sceneNode transform orthonormal: (WMMatrix3F xrot: Float halfPi negated ).
	sceneNode stateChanged
]

{ #category : #physics }
RWElement >> mass [
	^ mass
]

{ #category : #physics }
RWElement >> mass: aNumber [
	mass := aNumber asFloat
]

{ #category : #accessing }
RWElement >> model [
	^ model
]

{ #category : #accessing }
RWElement >> model: anObject [
	model := anObject
]

{ #category : #accessing }
RWElement >> orientation [
	^ sceneNode transform matrix
]

{ #category : #accessing }
RWElement >> orientation: anOrientation [
	sceneNode transform orthonormal: anOrientation asWMMatrix3F
]

{ #category : #accessing }
RWElement >> orientationMatrix [
	^ sceneNode transform matrix
]

{ #category : #accessing }
RWElement >> position [
	^ sceneNode transform translation
]

{ #category : #accessing }
RWElement >> position: aPosition [
	^ sceneNode transform translation: aPosition
]

{ #category : #'ray casting' }
RWElement >> rayCast: ray [
	| worldBoundingBox distance |
	worldBoundingBox := self boundingBox.
	worldBoundingBox isEmpty ifTrue: [ ^ 0 -> nil ].
	
	distance := ray intersectionDistanceWithBox: worldBoundingBox.
	(distance isNil or: [distance < 0]) ifTrue: [ ^ distance -> nil ].
	^ distance -> self.
]

{ #category : #adding }
RWElement >> remove [
	"Remove the element from the view it is contained in. Sending #remove to an element has the effect of making it diseapper from the screen. The Virtual Buffer are also correctly updated"
    self view removeElement: self.
    sceneNode removeFromParent.
    view signalUpdate.
]

{ #category : #accessing }
RWElement >> renderable [
	^ renderable 
]

{ #category : #adding }
RWElement >> replaceSceneNode: newNode [
	newNode transform: sceneNode transform.
	sceneNode := newNode.
]

{ #category : #physics }
RWElement >> rigidBody [
	^ rigidBody
]

{ #category : #orientation }
RWElement >> rotateByX: angle [
	sceneNode transform rotateRadiansOnX: angle.
	sceneNode stateChanged
]

{ #category : #orientation }
RWElement >> rotateByXDegrees: angle [
	sceneNode transform rotateDegreesOnX: angle.
	sceneNode stateChanged
]

{ #category : #orientation }
RWElement >> rotateByY: angle [
	sceneNode transform rotateRadiansOnY: angle.
	sceneNode stateChanged
]

{ #category : #orientation }
RWElement >> rotateByYDegrees: angle [
	sceneNode transform rotateDegreesOnY: angle.
	sceneNode stateChanged
]

{ #category : #orientation }
RWElement >> rotateByZ: angle [
	sceneNode transform rotateRadiansOnZ: angle.
	sceneNode stateChanged
]

{ #category : #orientation }
RWElement >> rotateByZDegrees: angle [
	sceneNode transform rotateDegreesOnZ: angle.
	sceneNode stateChanged
]

{ #category : #accessing }
RWElement >> sceneNode [
	^ sceneNode
]

{ #category : #accessing }
RWElement >> shape [
	^ shape
]

{ #category : #accessing }
RWElement >> shape: aShape [
	"
	Set the shape of the element
	
	:: RWShape -> RWElement
	"
	shape := aShape
]

{ #category : #'trachel compatibility' }
RWElement >> signalUpdate [
	"do nothing"
	self changed
]

{ #category : #updating }
RWElement >> simulateTime: delta [
	behaviors do: [ :behavior | behavior simulateTime: delta onElement: self]
]

{ #category : #'trachel compatibility' }
RWElement >> trachelShape [
	"Compatibility layer"
	^ self
]

{ #category : #accessing }
RWElement >> transform [
	^ sceneNode transform
]

{ #category : #translation }
RWElement >> translateBy: translation [
	sceneNode transform translateBy: translation.
	sceneNode stateChanged
]

{ #category : #translation }
RWElement >> translateByX: translation [
	self translateBy: (WMVector3F new x: translation)
]

{ #category : #translation }
RWElement >> translateByX: x y: y z: z [
	self translateBy: (WMVector3F x: x y: y z: z)
]

{ #category : #translation }
RWElement >> translateByY: translation [
	self translateBy: (WMVector3F new y: translation)
]

{ #category : #translation }
RWElement >> translateByZ: translation [
	self translateBy: (WMVector3F new z: translation)
]

{ #category : #translation }
RWElement >> translateTo: aWMVector3 [
	sceneNode transform translation: aWMVector3.
	sceneNode stateChanged
]

{ #category : #translation }
RWElement >> translateToX: newX [
	self translateTo: (self position x: newX)
]

{ #category : #translation }
RWElement >> translateToX: newX y: newY z: newZ [ 
	sceneNode transform translation: (WMVector3F x: newX asFloat y: newY asFloat z: newZ asFloat).
	sceneNode stateChanged
]

{ #category : #translation }
RWElement >> translateToY: newY [
	self translateTo: (self position y: newY)
]

{ #category : #translation }
RWElement >> translateToZ: newZ [
	self translateTo: (self position z: newZ)
]

{ #category : #accessing }
RWElement >> view [
	^ view
]

{ #category : #physics }
RWElement >> wall [
	mass := 0.0
]

{ #category : #accessing }
RWElement >> width [
	^ shape widthFor: self
]