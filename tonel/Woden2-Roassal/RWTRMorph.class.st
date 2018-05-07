Class {
	#name : #RWTRMorph,
	#superclass : #TRMorph,
	#instVars : [
		'engine'
	],
	#category : 'Woden2-Roassal-Trachel'
}

{ #category : #accessing }
RWTRMorph >> canvas: aTrachelCanvas [
	trachelCanvas := aTrachelCanvas.
	surface := WTAthensSurface engine: engine extent: self extent.
]

{ #category : #accessing }
RWTRMorph >> createSurface [
	surface := WTAthensSurface engine: engine extent: self extent asIntegerPoint.
	session := Smalltalk session.
]

{ #category : #accessing }
RWTRMorph >> engine [
	^ engine
]

{ #category : #accessing }
RWTRMorph >> engine: anObject [
	engine := anObject
]