Class {
	#name : #RWSceneView,
	#superclass : #WDASceneViewWith2DOverlay,
	#instVars : [
		'dragElement',
		'mouseFocusElement',
		'trackedDevicesDisplay',
		'vrTrackedDevices',
		'vrCameraBaseTransform'
	],
	#category : #'WodenEngine-Roassal-Core'
}

{ #category : #'rendering process stages' }
RWSceneView >> applyVRCameraTransform [
	| cameraTransform |
	cameraTransform := vrCameraBaseTransform copy.
 	self ensureVRTrackedDeviceDisplay: cameraTransform.

	cameraTransform := cameraTransform transformTransform: engine vrSystem hmdTrackedDevice currentPose deviceToAbsoluteTransform.
	self camera transform: cameraTransform
]

{ #category : #rendering }
RWSceneView >> buildUISceneGraphWith: builder [
	| result |
	result := super buildUISceneGraphWith: builder.
	model ifNotNil: [
		result := result , (model buildUISceneGraphWith: builder)
	].
	^ result
]

{ #category : #'rendering process stages' }
RWSceneView >> createVRTrackedDeviceModelFor: vrTrackedDevice [
	vrTrackedDevice isController ifTrue: [ ^ (RWVRTrackedController for: self device: vrTrackedDevice) ].
	vrTrackedDevice isGenericTracker ifTrue: [ ^ (RWVRGenericTrackedDevice for: self device: vrTrackedDevice) ].
	^ nil
]

{ #category : #visiting }
RWSceneView >> dispatchMouseOverElementsEvent: event newElement: elementBeingPointed [
	| leave enter move |
	self mouseFocusElement ~~ elementBeingPointed ifTrue: [
		leave := RWMouseLeave new.
		leave element: self mouseFocusElement;
			position: event position;
			sendToElement.

		enter := RWMouseEnter new.
		enter element: elementBeingPointed;
			position: event position;
			sendToElement.
		mouseFocusElement := elementBeingPointed.
	] ifFalse: [
		move := RWMouseMove new.
		move element: elementBeingPointed;
			position: event position;
			delta: event delta;
			sendToElement.
	].
]

{ #category : #selection }
RWSceneView >> elementInPosition: aPoint [
	^ self elementInPositionWithRayPicking: aPoint

]

{ #category : #selection }
RWSceneView >> elementInPositionWithRayPicking: aPoint [
	| nx ny extent |
	extent := self extent.
	nx := aPoint x / extent x asFloat.
	ny := 1.0 - (aPoint y / extent y).
	^ model rayPickNormalizedPosition: nx @ ny.

]

{ #category : #'rendering process stages' }
RWSceneView >> ensureVRTrackedDeviceDisplay: baseCameraTransform [
	engine vrSystem trackedDevices select: [:dev | dev isNotNil] thenDo: [ :eachTrackedDevice |
		(vrTrackedDevices at: eachTrackedDevice ifAbsentPut: [ 
			self createVRTrackedDeviceModelFor: eachTrackedDevice
		]) ifNotNil: [ :vrTrackedDevice |
			vrTrackedDevice transform: (baseCameraTransform transformTransform: eachTrackedDevice currentPose deviceToAbsoluteTransform)
		]
	].

]

{ #category : #initialization }
RWSceneView >> initialize [
	super initialize.
	vrTrackedDevices := Dictionary new.
	vrCameraBaseTransform := ReversibleAffineTransform3dF32 identity.
]

{ #category : #visiting }
RWSceneView >> mouseFocusElement [
	^ mouseFocusElement ifNil: [ mouseFocusElement := model ]
]

{ #category : #'as yet unclassified' }
RWSceneView >> projectPointToScreen: aPoint [
	| viewPoint projectionMatrix projectedPoint ndcPoint ndcX ndcY extent x y |
	camera ifNil: [ ^ 0@0 ].
	viewPoint := camera sceneNode globalTransform inverseTransformPosition: aPoint.
	projectionMatrix := camera sceneNode projectionMatrix.
	projectionMatrix ifNil: [ ^ 0@0 ].
	projectedPoint := projectionMatrix * (Float32x4 xyz: viewPoint w: 1.0).
	(projectedPoint w closeTo: 0.0) ifTrue: [ ^ 0@0 ].
	(projectedPoint z >= 0.0) ifTrue: [ ^ 0@0 ].
	
	ndcPoint := projectedPoint xyz / projectedPoint w.
	ndcX := ndcPoint x * 0.5 + 0.5.
	ndcY := ndcPoint y * 0.5 + 0.5.
	extent := self extent.
	x := ndcX * extent x.
	y := ndcY * extent y.

	^ x@y
]

{ #category : #visiting }
RWSceneView >> sendMouseEvent: event [
	model announce: event
]

{ #category : #'rendering process stages' }
RWSceneView >> updateForFrameDelta: delta [
	super updateForFrameDelta: delta.
	
	self isInVirtualReality ifTrue: [
		self updateVRForFrameDelta: delta
	].
	
	
]

{ #category : #'rendering process stages' }
RWSceneView >> updateVRForFrameDelta: delta [
	self applyVRCameraTransform.
	vrTrackedDevices valuesDo: [ :each | each ifNotNil: [each updateForFrameDelta: delta ]]
]

{ #category : #visiting }
RWSceneView >> visitJoyAxisEvent: event [
	| r3Event |
	event isPreferredEvent ifFalse: [ ^ self ].
	r3Event := RWJoyAxis new.
	r3Event which: event which;
		axis: event axis;
		value: event value.
	model announce: r3Event.

]

{ #category : #visiting }
RWSceneView >> visitJoyButtonDownEvent: event [
	| r3Event |
	event isPreferredEvent ifFalse: [ ^ self ].
	r3Event := RWJoyButtonDown new.
	r3Event which: event which;
		button: event button.
	model announce: r3Event.

]

{ #category : #visiting }
RWSceneView >> visitJoyButtonUpEvent: event [
	| r3Event |
	event isPreferredEvent ifFalse: [ ^ self ].
	r3Event := RWJoyButtonUp new.
	r3Event which: event which;
		button: event button.
	model announce: r3Event.

]

{ #category : #visiting }
RWSceneView >> visitKeyDownEvent: event [
	| r3Event |
	event symbol = OSK_F1 ifTrue: [ sceneRenderer debugNextRenderTarget ].
	event symbol = OSK_F2 ifTrue: [ sceneRenderer debugRenderNextShadowMapViewport ].
	
	r3Event := RWKeyDown new symbol: event symbol.
	model announce: r3Event.
	model signalUpdate

]

{ #category : #visiting }
RWSceneView >> visitKeyUpEvent: event [
	| r3Event |
	r3Event := RWKeyUp new symbol: event symbol.
	model announce: r3Event.
	model signalUpdate
]

{ #category : #visiting }
RWSceneView >> visitMouseButtonPressEvent: event [
	"event is an OSMouseButtonPressEvent"
	| r3Event cls |
	self isInVirtualReality ifTrue: [ ^ self ].
	
	cls := RWMouseButtonDown.
	
	"Is left button"
	event 	buttons button1 ifTrue: [ cls := RWMouseLeftButtonDown ].
	event 	buttons button2 ifTrue: [ cls := RWMouseRightButtonDown ].

	r3Event := cls new 
		buttons: event buttons;
		button: event button;
		position: event position;
		element: (self elementInPosition: event position).
	r3Event sendToElement.
]

{ #category : #visiting }
RWSceneView >> visitMouseButtonReleaseEvent: event [
	| r3Event |
	self isInVirtualReality ifTrue: [ ^ self ].
	
	r3Event := RWMouseButtonUp new buttons: event buttons;
		position: event position asFloat32x2;
		button: event button.
	r3Event element: (self elementInPosition: event position).
	self sendMouseEvent: r3Event.
]

{ #category : #visiting }
RWSceneView >> visitMouseDragEndEvent: event [
	"event is an OSMouseButtonPressEvent"
	| r3Event |
	self isInVirtualReality ifTrue: [ ^ self ].
	
	r3Event := RWMouseDragEnd new
		button: event button;
		position: event position;
		element: dragElement.
	r3Event sendToElement.
]

{ #category : #visiting }
RWSceneView >> visitMouseDragEvent: event [
	| r3Event |
	"Disable mouse move in VR mode."
	self isInVirtualReality ifTrue: [ ^ self ].
	r3Event := RWMouseDrag new buttons: event buttons;
		position: event position asFloat32x2;
		delta: event delta asFloat32x2;
		element: dragElement.
	r3Event sendToElement.

]

{ #category : #visiting }
RWSceneView >> visitMouseDragStartEvent: event [
	"event is an OSMouseButtonPressEvent"
	| r3Event |
	self isInVirtualReality ifTrue: [ ^ self ].
	
	r3Event := RWMouseDragStart new
		button: event button;
		position: event position;
		element: (self elementInPosition: event position).
	dragElement := r3Event element.
	r3Event sendToElement.
]

{ #category : #visiting }
RWSceneView >> visitMouseMoveEvent: event [
	| elementBeingPointed |
	"Disable mouse move in VR mode."
	self isInVirtualReality ifTrue: [ ^ self ].
	elementBeingPointed := self elementInPosition: event position.
	self dispatchMouseOverElementsEvent: event newElement: elementBeingPointed
]

{ #category : #visiting }
RWSceneView >> visitMouseWheelEvent: event [
	| r3Event |
	"Disable mouse move in VR mode."
	self isInVirtualReality ifTrue: [ ^ self ].
	r3Event := RWMouseWheel new buttons: event buttons;
		position: event position asFloat32x2;
		scrollHorizontal: event scrollHorizontal;
		scrollVertical: event scrollVertical;
		element: (self elementInPosition: event position).
	r3Event sendToElement.

]

{ #category : #accessing }
RWSceneView >> vrCameraBaseTransform [
	^ vrCameraBaseTransform
]
