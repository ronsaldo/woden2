Class {
	#name : #WDESBalloonDrivingCharacterController,
	#superclass : #WDESCharacterDrivingVehicleDisplacementStrategy,
	#instVars : [
		'driverEntryPosition',
		'drivingTime',
		'localDriverPosition'
	],
	#category : #'WodenEngine-EntitySystem-Samples'
}

{ #category : #'as yet unclassified' }
WDESBalloonDrivingCharacterController >> applyVehicleAngleDelta: angleDelta [
	character headAngle: character headAngle + (Float32x3 y: angleDelta)
]

{ #category : #initialization }
WDESBalloonDrivingCharacterController >> character: aCharacter [
	super character: aCharacter.
	driverEntryPosition := character ownerEntity sectorTransform translation.
]

{ #category : #initialization }
WDESBalloonDrivingCharacterController >> initialize [
	super initialize.
	localDriverPosition := Float32x3 zeros.
	driverEntryPosition := Float32x3 zeros.
	drivingTime := 0.0.
]

{ #category : #accessing }
WDESBalloonDrivingCharacterController >> localDriverPosition [
	^ localDriverPosition
]

{ #category : #accessing }
WDESBalloonDrivingCharacterController >> localDriverPosition: anObject [
	localDriverPosition := anObject
]

{ #category : #initialization }
WDESBalloonDrivingCharacterController >> prePhysicsTick: delta [
	| stickDirection |
	super prePhysicsTick: delta.
	
	stickDirection := character leftStickDirection.
	vehicleKinematicBehavior
		engineDirection: stickDirection y;
		turnDirection: stickDirection x;
		altitudeDirection: (stickDirection z max: 0.0).
	drivingTime := drivingTime + delta
]

{ #category : #initialization }
WDESBalloonDrivingCharacterController >> vehicleDriverPosition [
	^ driverEntryPosition interpolateTo: (vehicle sectorTransform transformPosition: localDriverPosition) at: (drivingTime smoothStepFrom: 0.0 to: 0.8)
]
