Class {
	#name : #WDSLightedSceneRendererViewport,
	#superclass : #WDSAbstractSceneRendererViewport,
	#instVars : [
		'lights',
		'sortedLights',
		'selectedLights',
		'lightRenderingStates'
	],
	#category : #'WodenEngine-Scene-Rendering'
}

{ #category : #adding }
WDSLightedSceneRendererViewport >> addLight: aLight [
	lights add: aLight
]

{ #category : #initialization }
WDSLightedSceneRendererViewport >> initialize [
	super initialize.
	lights := OrderedCollection new.
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> lightRenderingStates [
	^ lightRenderingStates
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> lightRenderingStates: anObject [
	lightRenderingStates := anObject
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> lights [
	^ lights
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> lights: anObject [
	lights := anObject
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> selectedLights [
	^ selectedLights
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> selectedLights: anObject [
	selectedLights := anObject
]

{ #category : #sorting }
WDSLightedSceneRendererViewport >> sortAndSelectLights [
	| cameraPosition |
	cameraPosition := self camera renderTransform translation.
	
	sortedLights := lights collect: [ :light |
		{ light . (light renderTransform translation - cameraPosition) length2 }
	].
	sortedLights sort: [ :a :b |
		a second < b second
	].

	selectedLights := sortedLights first: (sortedLights size min: 16).

]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> sortedLights [
	^ sortedLights
]

{ #category : #accessing }
WDSLightedSceneRendererViewport >> sortedLights: anObject [
	sortedLights := anObject
]