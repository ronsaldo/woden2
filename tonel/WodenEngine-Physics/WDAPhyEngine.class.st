Class {
	#name : #WDAPhyEngine,
	#superclass : #WDPhyPhysicsEngine,
	#instVars : [
		'handle',
		'handleToObjectDictionary',
		'externalObjectCopies'
	],
	#pools : [
		'APHYConstants'
	],
	#category : #'WodenEngine-Physics-AbstractPhysics'
}

{ #category : #'as yet unclassified' }
WDAPhyEngine class >> isSupported [
	^ true
]

{ #category : #initialization }
WDAPhyEngine >> activateCollisionObject: collisionObject [
	(self getCollisionObjectHandle: collisionObject) activate
]

{ #category : #rendering }
WDAPhyEngine >> applyCollisionObjectFlags: collisionObject to: collisionObjectHandle [
	collisionObjectHandle
		setHasContactResponse: collisionObject hasCollisionResponse;
		setIsStaticObject: collisionObject isStaticObject;
		setIsKinematicObject: collisionObject isKinematicObject;
		setIsCharacterObject: collisionObject isCharacterObject;
		setDebugDrawingEnabled: collisionObject hasDebugDrawing.
]

{ #category : #'as yet unclassified' }
WDAPhyEngine >> buildCharacterController: characterController [
	| controllerHandle |
	controllerHandle := handle
			createKinematicCharacterController: (self validateGhostObjectHandle: characterController ghostObject)
			convex_shape: (self validateCollisionShapeHandle: characterController shape)
			step_height: characterController stepHeight
			up_axis: APHY_AXIS_Y.

	controllerHandle
		setJumpSpeed: characterController jumpSpeed;
		setGravity: characterController gravity negated;
		setWalkDirectionFrom: (self convertWMVector3: characterController linearVelocity / 120.0).
	characterController
		handle: controllerHandle;
		physicsEngine: self.
	handleToObjectDictionary at: controllerHandle put: characterController

]

{ #category : #rendering }
WDAPhyEngine >> buildCollisionShape: collisionShape [
	collisionShape
		handle: (collisionShape accept: self);
		physicsEngine: self.
	handleToObjectDictionary at: collisionShape handle put: collisionShape
]

{ #category : #'as yet unclassified' }
WDAPhyEngine >> buildGhostObject: ghostObject [
	ghostObject isGhostObjectWithPairCache ifTrue: [
		ghostObject handle: handle createPairCachingGhostObject
	] ifFalse: [
		ghostObject handle: handle createGhostObject
	].
	handleToObjectDictionary at: ghostObject handle put: ghostObject.
	ghostObject physicsEngine: self.
	ghostObject shape ifNotNil: [
		ghostObject handle setCollisionShape: (self validateCollisionShapeHandle: ghostObject shape)
	].
	ghostObject applyTransformInHandle.
	self applyCollisionObjectFlags: ghostObject to: ghostObject handle
	

]

{ #category : #rendering }
WDAPhyEngine >> buildRigidBody: rigidBody [
	| collisionShape localInertia motionState rigidBodyHandle |
	collisionShape := self validateCollisionShapeHandle: rigidBody shape.
	localInertia := APHYVector3 new.
	collisionShape computeLocalInertiaInto: rigidBody mass result: localInertia.
	
	motionState := handle createDefaultMotionState.
	rigidBodyHandle := handle createSimpleRigidBodyFrom: rigidBody mass motion_state: motionState collision_shape: collisionShape local_inertia: localInertia.
	handleToObjectDictionary at: rigidBodyHandle put: rigidBody.
	
	rigidBody
		handle: { rigidBodyHandle . motionState };
		physicsEngine: self.
	self applyCollisionObjectFlags: rigidBody to: rigidBodyHandle
]

{ #category : #'character controller' }
WDAPhyEngine >> canCharacterJump: characterController [
	^ (self validateCharacterControllerHandle: characterController) canJump
]

{ #category : #'character controller' }
WDAPhyEngine >> characterController: characterController setGravity: gravity jumpSpeed: jumpSpeed [
	(self validateCharacterControllerHandle: characterController)
		setGravity: gravity negated;
		setJumpSpeed: jumpSpeed
]

{ #category : #'character controller' }
WDAPhyEngine >> characterController: characterController setLinearVelocity: velocity [
	| walkDirection |
	walkDirection := self convertWMVector3: velocity / 120.0.
	(self validateCharacterControllerHandle: characterController) setWalkDirectionFrom: walkDirection
]

{ #category : #'character controller' }
WDAPhyEngine >> characterJump: characterController [
	^ (self validateCharacterControllerHandle: characterController) jump
]

{ #category : #rendering }
WDAPhyEngine >> collisionMesh: mesh addedToCollection: collection [
	collection handle addCollisionMeshAccessor: (APHYCollisionMeshAccessor new
		vertices: (self externalCopyOf: mesh vertexBufferData);
		vertex_offset: mesh vertexBufferOffset;
		vertex_stride: mesh vertexBufferStride;
		vertex_count: mesh vertexCount;
		indices: (self externalCopyOf: mesh indexBufferData);
		index_offset: mesh indexBufferOffset;
		index_stride: mesh indexBufferStride;
		index_count: mesh indexCount;
		yourself
	)
	transform: (mesh transform ifNotNil: [self convertWMTransform: mesh transform])

]

{ #category : #rendering }
WDAPhyEngine >> convertMatrix3: matrix3 [
	| firstRow secondRow thirdRow |
	firstRow := matrix3 firstRow.
	secondRow := matrix3 secondRow.
	thirdRow := matrix3 thirdRow.
	^ Float32x3x3 rows: {
		firstRow x . firstRow y . firstRow z.
		secondRow x . secondRow y . secondRow z.
		thirdRow x . thirdRow y . thirdRow z.
	}

]

{ #category : #rendering }
WDAPhyEngine >> convertTransform: transform [
	| matrix translation |
	matrix := self convertMatrix3: transform rotation.
	translation := self convertVector3: transform origin.
	^ ReversibleAffineTransform3dF32 new orthonormal: matrix translation: translation
]

{ #category : #rendering }
WDAPhyEngine >> convertVector3: vector3 [
	^ Float32x3 x: vector3 x y: vector3 y z: vector3 z
]

{ #category : #rendering }
WDAPhyEngine >> convertWMMatrix3: matrix [
	^ APHYMatrix3x3 new
		firstRow: (self convertWMVector3: matrix firstRow);
		secondRow: (self convertWMVector3: matrix secondRow);
		thirdRow: (self convertWMVector3: matrix thirdRow);
		yourself
]

{ #category : #rendering }
WDAPhyEngine >> convertWMTransform: transform [
	^ APHYTransform new
		rotation: (self convertWMMatrix3: transform matrix);
		origin: (self convertWMVector3: transform translation);
		yourself
]

{ #category : #rendering }
WDAPhyEngine >> convertWMVector3: vector [
	^ APHYVector3 new
		x: vector x;
		y: vector y;
		z: vector z;
		yourself
]

{ #category : #'as yet unclassified' }
WDAPhyEngine >> createDynamicsWorld [
	| collisionConfiguration collisionDispatcher broadphase constraintSolver world |
	collisionConfiguration := handle createDefaultCollisionConfiguration.
	collisionDispatcher := handle createDefaultCollisionDispatcher: collisionConfiguration.

	broadphase := handle createDefaultBroadphase.
	constraintSolver := handle createDefaultConstraintSolver.

	world := handle createDynamicsWorld: collisionDispatcher broadphase: broadphase constraint_solver: 	constraintSolver collision_configuration: collisionConfiguration.
		
	^ WDAPhyDynamicsWorld new physicsEngine: self; handle: world; yourself
]

{ #category : #'as yet unclassified' }
WDAPhyEngine >> externalCopyOf: byteArray [
	^ externalObjectCopies at: byteArray ifAbsentPut: [
		| externalBuffer |
		externalBuffer := ExternalAddress gcallocate: byteArray size.
		LibC memCopy: byteArray to: externalBuffer size: byteArray size.
		ExternalData fromHandle: externalBuffer type: ExternalType void
	]
]

{ #category : #'collision object' }
WDAPhyEngine >> getCollisionObjectHandle: collisionObject [
	^ collisionObject handle isArray ifTrue: [ 
		collisionObject handle first
	] ifFalse: [
		collisionObject handle
	].

]

{ #category : #'collision object' }
WDAPhyEngine >> getCollisionObjectPosition: collisionObject [
	| result |
	result := APHYVector3 new.
	(self getCollisionObjectHandle: collisionObject) getTranslationInto: result.
	^ self convertVector3: result
]

{ #category : #'as yet unclassified' }
WDAPhyEngine >> getObjectFromHandle: objectHandle [
	^ handleToObjectDictionary at: objectHandle ifAbsent: [ nil ]

]

{ #category : #accessing }
WDAPhyEngine >> handle [
	^ handle
]

{ #category : #initialization }
WDAPhyEngine >> initialize [
	super initialize.
	handle := APHY firstEngine.
	handleToObjectDictionary := WeakKeyDictionary new.
	externalObjectCopies := WeakKeyDictionary new.
]

{ #category : #'collision object' }
WDAPhyEngine >> setCollisionObject: collisionObject linearVelocity: velocity [
	(self getCollisionObjectHandle: collisionObject)
		setLinearVelocityFrom: (self convertWMVector3: velocity)
]

{ #category : #initialization }
WDAPhyEngine >> setCollisionObject: collisionObject orientation: orientation [
	| collisionObjectHandle |
	collisionObjectHandle := collisionObject handle.
	collisionObjectHandle isArray ifTrue: [
		collisionObject isKinematicObject ifTrue: [ 
			collisionObjectHandle second setMatrixFrom: (self convertWMMatrix3: orientation).
		] ifFalse: [ 
			collisionObjectHandle first setMatrixFrom: (self convertWMMatrix3: orientation).
		].
	] ifFalse: [ 
		collisionObjectHandle setMatrixFrom: (self convertWMMatrix3: orientation).
	]

]

{ #category : #initialization }
WDAPhyEngine >> setCollisionObject: collisionObject position: position [
	| collisionObjectHandle |
	collisionObjectHandle := collisionObject handle.
	collisionObjectHandle isArray ifTrue: [
		collisionObject isKinematicObject ifTrue: [ 
			collisionObjectHandle second setTranslationFrom: (self convertWMVector3: position).
		] ifFalse: [ 
			collisionObjectHandle first setTranslationFrom: (self convertWMVector3: position).
		]
	] ifFalse: [ 
		collisionObjectHandle setTranslationFrom: (self convertWMVector3: position).
	]

]

{ #category : #rendering }
WDAPhyEngine >> validateCharacterControllerHandle: characterController [
	(characterController handle isNil or: [ characterController handle isNull ]) ifTrue: [
		self buildCharacterController: characterController
	].
	^ characterController handle
]

{ #category : #rendering }
WDAPhyEngine >> validateCollisionMeshCollection: collection [
	(collection handle isNil or: [ collection handle isNull ]) ifTrue: [
		collection physicsEngine: self;
			handle: handle createCollisionMeshCollection.
		collection collisionMeshes do: [ :mesh |
			self collisionMesh: mesh addedToCollection: collection
		].
	].
	^ collection handle
]

{ #category : #rendering }
WDAPhyEngine >> validateCollisionShapeHandle: collisionShape [
	(collisionShape handle isNil or: [ collisionShape handle isNull ]) ifTrue: [
		self buildCollisionShape: collisionShape
	].
	^ collisionShape handle
]

{ #category : #rendering }
WDAPhyEngine >> validateGhostObjectHandle: ghostObject [
	(ghostObject handle isNil or: [ ghostObject handle isNull ]) ifTrue: [
		self buildGhostObject: ghostObject
	].
	^ ghostObject handle
]

{ #category : #rendering }
WDAPhyEngine >> validateRigidBodyHandle: rigidBody [
	(rigidBody handle isNil or: [ rigidBody handle first isNull ]) ifTrue: [
		self buildRigidBody: rigidBody
	].
	^ rigidBody handle
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitBoxShape: boxShape [
	^ handle createBoxShape: boxShape halfExtent x half_height: boxShape halfExtent y half_depth: boxShape halfExtent z
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitCapsuleXShape: capsuleShape [
	^ handle createCapsuleShapeX: capsuleShape radius height: capsuleShape height
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitCapsuleYShape: capsuleShape [
	^ handle createCapsuleShapeY: capsuleShape radius height: capsuleShape height
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitCapsuleZShape: capsuleShape [
	^ handle createCapsuleShapeX: capsuleShape radius height: capsuleShape height
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitCompoundShape: compoundShape [
	| compoundHandle localTransform localShape |
	compoundHandle := handle createCompoundShape.
	compoundShape components do: [ :component |
		localTransform := self convertWMTransform: component transform.
		localShape := self validateCollisionShapeHandle: component shape.
		compoundHandle addLocalShapeWithTransformFrom: localShape transform: localTransform.
	].
	^ compoundHandle
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitConvexHullShape: convexHullShape [
	| points |
	points := convexHullShape points.
	^ handle createConvexHullShape: points rawData num_points: points size stride: points elementSize

]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitHeightFieldCollisionShape: heightFieldShape [
	| heightFieldHandle texture textureLevel heightScale |
	texture := heightFieldShape heightTexture.
	textureLevel := texture data layers first levels first.
	heightScale := heightFieldShape heightScale.

	textureLevel data pinInMemory.
	heightFieldHandle := handle createHeightfieldTerrainShape: textureLevel width height_stick_length: textureLevel height heightfield_data: textureLevel data
		height_scale: heightScale / ( ((1<<15) - 1) asFloat)
		min_height: heightFieldShape minHeight max_height: heightFieldShape maxHeight
		up_axis: APHY_AXIS_Y
		height_data_type: APHY_SCALAR_TYPE_SHORT flip_quad_edges: false
		local_scale_x: 2.0*heightFieldShape scale x reciprocal / textureLevel width
		local_scale_y: 1.0
		local_scale_z: 2.0*heightFieldShape scale y reciprocal / textureLevel height.

	^ heightFieldHandle
]

{ #category : #'collision shape convertion' }
WDAPhyEngine >> visitTriangleMeshShape: triangleMeshShape [
	| collisionMeshCollectionHandle |
	collisionMeshCollectionHandle := self validateCollisionMeshCollection: triangleMeshShape collisionMeshCollection.
	^ handle createTriangleMeshCollisionShape: collisionMeshCollectionHandle
]
