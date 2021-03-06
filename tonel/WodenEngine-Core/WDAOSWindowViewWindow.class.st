"
I am an OSWindow based view window for a Woden application.
"
Class {
	#name : #WDAOSWindowViewWindow,
	#superclass : #WDCOSWindow,
	#instVars : [
		'view'
	],
	#category : #'WodenEngine-Core-Application'
}

{ #category : #'instance creation' }
WDAOSWindowViewWindow class >> for: aView [
	^ self basicNew
		view: aView;
		initialize;
		yourself
]

{ #category : #'instance creation' }
WDAOSWindowViewWindow >> close [
	view ifNotNil: [view closed].
	^ super close
]

{ #category : #accessing }
WDAOSWindowViewWindow >> defaultExtent [
	^ view defaultExtent
]

{ #category : #'framebuffer description' }
WDAOSWindowViewWindow >> hasDepth [
	^ view hasDepth
]

{ #category : #'framebuffer description' }
WDAOSWindowViewWindow >> hasStencil [
	^ view hasStencil
]

{ #category : #'framebuffer description' }
WDAOSWindowViewWindow >> needsDirectRenderTarget [
	^ view needsDirectRenderTarget
]

{ #category : #'event processing' }
WDAOSWindowViewWindow >> processEvent: anEvent [
	super processEvent: anEvent.
	handledHere ifTrue: [ ^ self ].
	
	view ifNotNil: [ view handleEvent: anEvent ]
]

{ #category : #'framebuffer description' }
WDAOSWindowViewWindow >> sampleCount [
	^ view windowSampleCount
]

{ #category : #accessing }
WDAOSWindowViewWindow >> view [
	^ view
]

{ #category : #accessing }
WDAOSWindowViewWindow >> view: anObject [
	view := anObject
]

{ #category : #'event processing' }
WDAOSWindowViewWindow >> visitWindowCloseEvent: anEvent [
	view ifNil: [ ^ super visitWindowCloseEvent: anEvent ]
]

{ #category : #'event processing' }
WDAOSWindowViewWindow >> visitWindowExposeEvent: anEvent [
	view ifNotNil: [ view changed ]
]

{ #category : #'event processing' }
WDAOSWindowViewWindow >> visitWindowResizeEvent: anEvent [
	view ifNotNil: [ view changed ]
]
