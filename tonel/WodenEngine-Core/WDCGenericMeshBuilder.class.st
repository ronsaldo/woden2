"
I am a generic mesh builder. I am used for building meshes.
"
Class {
	#name : #WDCGenericMeshBuilder,
	#superclass : #WDCAbstractMeshBuilder,
	#instVars : [
		'vertices',
		'indices',
		'currentColor',
		'currentMaterial',
		'submeshes',
		'baseVertex',
		'boundingBox',
		'vertexData',
		'vertexClass',
		'lastUsedVertexForCollision'
	],
	#pools : [
		'AGPUConstants'
	],
	#category : #'WodenEngine-Core-Mesh'
}

{ #category : #adding }
WDCGenericMeshBuilder >> addCircleCenter: center radius: radius slices: slices isTop: isTop [
	| normal position phi x z firstSlice secondSlice|
	self beginTriangles.
	
	isTop ifTrue: [ normal := Float32x3 x: 0.0 y: 1.0 z: 0.0 ] ifFalse: [ normal := Float32x3 x: 0.0 y: -1.0 z: 0.0 ].
	self addP: center N: normal TC: (Float32x2 x: 0.0 y: 0.0).
	
	0 to: (slices - 1) do: [ :slice |
		firstSlice := slice + 2.
		secondSlice := (slice + 1) % slices + 2.
		phi := (Float twoPi  * slice) / (slices - 1).
		x := phi cos * radius.
		z := phi sin * radius.
		position := center + (Float32x3 x: x y: 0.0 z: z).
		self addP: position N: normal TC: (Float32x2 x: x y: z).
		isTop ifTrue: [
			self addI1: firstSlice i2: 1 i3: secondSlice .
		] ifFalse: [ 
			self addI1: secondSlice i2: 1 i3: firstSlice .
		]
	].
]

{ #category : #adding }
WDCGenericMeshBuilder >> addCircleCenter: center radius: radius slices: slices orientation: orientation color: color isTop: isTop [
	| firstSlice secondSlice|
	self beginTriangles.
	
	self addP: center C: color.
	
	0 to: (slices - 1) do: [ :slice |
		| position phi x z |
		firstSlice := slice + 2.
		secondSlice := (slice + 1) % slices + 2.
		phi := (Float twoPi  * slice) / (slices - 1).
		x := phi cos * radius.
		z := phi sin * radius.
		position := orientation * (Float32x3 x: x y: 0.0 z: z) + center.
		self addP: position C: color.
		isTop ifTrue: [
			self addI1: firstSlice i2: 1 i3: secondSlice .
		] ifFalse: [ 
			self addI1: secondSlice i2: 1 i3: firstSlice .
		]
	].
]

{ #category : #collisions }
WDCGenericMeshBuilder >> addCollisionBox [
	| box |
	box := BoxF32 empty.
	lastUsedVertexForCollision + 1 to: vertices size do: [ :i |
		box insertPoint: (vertices at: i) position asFloat32x3
	].

	lastUsedVertexForCollision := vertices size.
	collisionShapes add: (self createAABoxCollisionShape: box)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addConeRadius: baseRadius height: height segments: segments slices: slices [
	| normal position texcoord radius phi x y z firstRow secondRow firstSlice secondSlice |
	self beginTriangles.
	"Add the vertices"
	(0 to: segments - 1) do: [ :segment |
		y := (height*(segment/(segments - 1))) - (height*0.5).
		radius := baseRadius*(segments - 1 - segment)/(segments - 1).
				
		(0 to: slices - 1) do: [ :slice |
			phi := (Float twoPi  * slice) / (slices - 1).
			x := phi cos.
			z := phi sin.
			position := (Float32x3 x: x * radius y: y z: z * radius).
			normal := Float32x3 x: x y: 0.0 z: z.
			texcoord := Float32x2 x: phi / Float twoPi y: (segment/(segments - 1)) asFloat.
			self addP: position N: normal TC: texcoord.
		].		
	].

	"Add the quads"
	(0 to: segments - 2) do: [ :segment |
		firstRow := segment*slices.
		secondRow := (segment+1)*slices.
		(0 to: slices - 1) do: [ :slice |
			firstSlice := slice + 1.
			secondSlice := (slice + 1) % slices + 1.
			self addQuadI1: firstRow + secondSlice i2: firstRow+firstSlice i3: secondRow+firstSlice i4: secondRow+secondSlice.
		]
	].

	"Add the caps"
	self addCircleCenter: (Float32x3 x: 0.0 y: height * -0.5 z: 0.0) radius: radius slices: slices isTop: false.

]

{ #category : #collisions }
WDCGenericMeshBuilder >> addConvexHull [
	| points |
	points := OrderedCollection new.
	lastUsedVertexForCollision + 1 to: vertices size do: [ :i |
		points add: (vertices at: i) position asFloat32x3
	].

	lastUsedVertexForCollision := vertices size.
	collisionShapes add: (self createConvexHullCollisionShape: points)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addCubeWithWidth: width height: height depth: depth [
	| px py pz nx ny nz |
	self beginTriangles.
	
	px := width * 0.5.
	py := height * 0.5.
	pz := depth * 0.5.
	nx := width * -0.5.
	ny := height * -0.5.
	nz := depth * -0.5.
	
	"Back Face"
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 1 i2: 2 i3: 3.
	self addI1: 3 i2: 4 i3: 1.
	
	"Front Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 5 i2: 6 i3: 7.
	self addI1: 7 i2: 8 i3: 5.

	"Top Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 9 i2: 10 i3: 11.
	self addI1: 11 i2: 12 i3: 9.
	
	"Bottom Face"
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 13 i2: 14 i3: 15.
	self addI1: 15 i2: 16 i3: 13.

	"Left Face"
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 17 i2: 18 i3: 19.
	self addI1: 19 i2: 20 i3: 17.

	"Right Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 21 i2: 22 i3: 23.
	self addI1: 23 i2: 24 i3: 21.

]

{ #category : #adding }
WDCGenericMeshBuilder >> addCylinderRadius: radius height: height segments: segments slices: slices [
	self addCylinderRadius: radius height: height segments: segments slices: slices capBottom: true capTop: true
]

{ #category : #adding }
WDCGenericMeshBuilder >> addCylinderRadius: radius height: height segments: segments slices: slices capBottom: capBottom capTop: capTop [
	| normal position texcoord phi x y z firstRow secondRow firstSlice secondSlice |
	self beginTriangles.
	"Add the vertices"
	0 to: segments - 1 do: [ :segment |
		y := (height*(segment/(segments - 1))) - (height*0.5).
		
		0 to: slices - 1 do: [ :slice |
			phi := (Float twoPi  * slice) / (slices - 1).
			x := phi cos.
			z := phi sin.
			position := (Float32x3 x: x * radius y: y z: z * radius).
			normal := Float32x3 x: x y: 0.0 z: z.
			texcoord := Float32x2 x: phi / Float twoPi y: (segment/(segments - 1)) asFloat.
			self addP: position N: normal TC: texcoord.
		].		
	].

	"Add the quads"
	0 to: segments - 2 do: [ :segment |
		firstRow := segment*slices.
		secondRow := (segment+1)*slices.
		0 to: slices - 1 do: [ :slice |
			firstSlice := slice + 1.
			secondSlice := (slice + 1) % slices + 1.
			self addQuadI1: firstRow + secondSlice i2: firstRow+firstSlice i3: secondRow+firstSlice i4: secondRow+secondSlice.
		]
	].

	"Add the caps"
	capBottom ifTrue: [ 
		self addCircleCenter: (Float32x3 x: 0.0 y: height * 0.5 z: 0.0) radius: radius slices: slices isTop: true.
	].
	capTop ifTrue: [
		self addCircleCenter: (Float32x3 x: 0.0 y: height * -0.5 z: 0.0) radius: radius slices: slices isTop: false.
	]
]

{ #category : #adding }
WDCGenericMeshBuilder >> addFloorWithWidth: width height: height depth: depth [
	| px   nx   py pz ny nz |
	"Voxel style a cube but in voxel heavy :-)"
	self beginTriangle.
	
	px := width * 0.5.
	nx := width * -0.5.
	
	1 to: width do:[:VWpositionInt | | VWposition minorTextCoord majorTextCoord i1 i2 i3 i4 |
		VWposition := VWpositionInt asFloat.
		minorTextCoord := ((VWposition - 1) / width) asFloat.
		majorTextCoord := (VWposition / width) asFloat.
		
		i1:= (VWpositionInt * 4).
		i2:= i1 + 1.
		i3:= i2 + 1.
		i4:= i3 + 1.
 	
		px := width * 0.5.
		py := height * 0.5.
		pz := depth * 0.5.
		nx := width * -0.5.
		ny := height * -0.5.
		nz := depth * -0.5.
	
		"Back Face"
		self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
		self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
		self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
		self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
		self addI1: 1 i2: 2 i3: 3.
		self addI1: 3 i2: 4 i3: 1.
	
	"Front Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 5 i2: 6 i3: 7.
	self addI1: 7 i2: 8 i3: 5.

	"Top Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 9 i2: 10 i3: 11.
	self addI1: 11 i2: 12 i3: 9.
	
	"Bottom Face"
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 13 i2: 14 i3: 15.
	self addI1: 15 i2: 16 i3: 13.

	"Left Face"
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 17 i2: 18 i3: 19.
	self addI1: 19 i2: 20 i3: 17.

	"Right Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 21 i2: 22 i3: 23.
	self addI1: 23 i2: 24 i3: 21.

		
		
		
		
		].

]

{ #category : #adding }
WDCGenericMeshBuilder >> addGridWithWidth: width height: height subdivisions: subdivisions [
	| dx dy sx sy x y s t rs rd|
	self beginTriangles.
	
	"Add vertices"
	dx := width / (subdivisions - 1).
	dy := height / (subdivisions - 1).
	sx := width * -0.5.
	sy := height * -0.5.
	y := sy.
	1 to: subdivisions do: [:j |
		x := sx.
		t := (j - 1) / (subdivisions - 1) asFloat.
		1 to: subdivisions do: [:i |
			s := (i - 1) / (subdivisions - 1) asFloat.
			self addP: (Float32x3 x: x y: 0.0 z: y) N: (Float32x3 x: 0.0 y: 1.0 z: 0.0) TC: (Float32x2 x: s y: t).
			x := x + dx.
		].
	
		y := y + dy.
	] .

	"Add quads"
	1 to: (subdivisions - 1) do: [:j |
		rs := j * subdivisions - subdivisions.
		rd := (j + 1) * subdivisions - subdivisions.
		
		1 to: (subdivisions - 1) do: [:i |
			self addI1: rd + i + 1 i2: rs + i + 1 i3: rs + i;
				addI1: rs + i i2: rd + i i3: rd + i + 1
		].
	].

]

{ #category : #adding }
WDCGenericMeshBuilder >> addI1: i1 i2: i2 [
	indices
		add: i1 + baseVertex - 1;
		add: i2 + baseVertex - 1
]

{ #category : #adding }
WDCGenericMeshBuilder >> addI1: i1 i2: i2 i3: i3 [
	indices
		add: i1 + baseVertex - 1;
		add: i2 + baseVertex - 1;
		add: i3 + baseVertex - 1
]

{ #category : #adding }
WDCGenericMeshBuilder >> addInteriorCubeWithWidth: width height: height depth: depth [
	| px py pz nx ny nz |
	self beginTriangles.
	
	px := width * 0.5.
	py := height * 0.5.
	pz := depth * 0.5.
	nx := width * -0.5.
	ny := height * -0.5.
	nz := depth * -0.5.
	
	"Back Face"
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: 0.0 y: 0.0 z: -1.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 3 i2: 2 i3: 1.
	self addI1: 1 i2: 4 i3: 3.
	
	"Front Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 0.0 y: 0.0 z: 1.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 7 i2: 6 i3: 5.
	self addI1: 5 i2: 8 i3: 7.

	"Top Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: 0.0 y: 1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 11 i2: 10 i3: 9.
	self addI1: 9 i2: 12 i3: 11.
	
	"Bottom Face"
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 0.0 y: -1.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 15 i2: 14 i3: 13.
	self addI1: 13 i2: 16 i3: 15.

	"Left Face"
	self addP: (Float32x3 x: nx y: ny z: pz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: pz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: nx y: py z: nz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: nx y: ny z: nz)  N: (Float32x3 x: -1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 19 i2: 18 i3: 17.
	self addI1: 17 i2: 20 i3: 19.

	"Right Face"
	self addP: (Float32x3 x: px y: py z: pz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: pz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 1.0).
	self addP: (Float32x3 x: px y: ny z: nz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 1.0 y: 0.0).
	self addP: (Float32x3 x: px y: py z: nz)  N: (Float32x3 x: 1.0 y: 0.0 z: 0.0 ) TC: (Float32x2 x: 0.0 y: 0.0).
	self addI1: 23 i2: 22 i3: 21.
	self addI1: 21 i2: 24 i3: 23.

]

{ #category : #adding }
WDCGenericMeshBuilder >> addLineFrom: start to: end [
	self
		beginLines;
		addP: start;
		addP: end.
	self addI1: 1 i2: 2
]

{ #category : #adding }
WDCGenericMeshBuilder >> addLineGridWithWidth: width height: height subdivisions: subdivisions [
	| dx dy x y px py nx ny tc  |
	
	"Add vertices"
	dx := width / (subdivisions - 1).
	dy := height / (subdivisions - 1).
	px := width * 0.5.
	py := height * 0.5.
	nx := px negated.
	ny := py negated.
	tc := Float32x2 new.
	x := nx.
	
	"Vertical lines"
	self beginLines.
	1 to: subdivisions do: [:i |
		self addP: (Float32x3 x: x y: ny z: 0.0) TC: tc.
		self addP: (Float32x3 x: x y: py z: 0.0) TC: tc.
		self addI1: i*2 - 1 i2: i*2.
		x := x + dx.
	].

	"Horizontal lines"
	self beginLines.
	y := ny.
	1 to: subdivisions do: [:i |
		self addP: (Float32x3 x: nx y: y z: 0.0) TC: tc.
		self addP: (Float32x3 x: px y: y z: 0.0) TC: tc.
		self addI1: i*2 - 1 i2: i*2.
		y := y + dy.
	].

]

{ #category : #adding }
WDCGenericMeshBuilder >> addP: position [
	vertices add: (WDCGenericVertexF32 new position: position; color: currentColor; yourself)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addP: position C: color [
	vertices add: (WDCGenericVertexF32 new position: position; color: color asFloat32x4 ; yourself)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addP: position N: normal [
	vertices add: (WDCGenericVertexF32 new position: position; normal: normal; color: currentColor; yourself)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addP: position N: normal T4: tangent4 TC: texcoord [
	vertices add: (WDCGenericVertexF32 new
		position: position;
		normal: normal;
		tangent4: tangent4;
		texcoord: texcoord;
		color: currentColor;
		yourself)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addP: position N: normal TC: texcoord [
	vertices add: (WDCGenericVertexF32 new position: position; normal: normal; texcoord: texcoord; color: currentColor; yourself)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addP: position TC: texcoord [
	vertices add: (WDCGenericVertexF32 new position: position; texcoord: texcoord; color: currentColor; yourself)
]

{ #category : #adding }
WDCGenericMeshBuilder >> addPolyLineWithPoints: points [
	self beginLines.
	points do: [ :eachPoint | self addP: eachPoint ].
	1 to: points size - 1 do: [ :i |
		self addI1: i i2: i + 1
	].
]

{ #category : #adding }
WDCGenericMeshBuilder >> addPolyLineWithPoints: points colors: colors [
	self assert: points size = colors size.
	self beginLines.
	1 to: points size do: [ :i |
		self addP: (points at: i) C: (colors at: i)
	].
	1 to: points size - 1 do: [ :i |
		self addI1: i i2: i + 1
	].
]

{ #category : #adding }
WDCGenericMeshBuilder >> addPolyLineWithPoints: points colors: colors radius: radius slices: slices [
	^ self addPolyLineWithPoints: points colors: colors radius: radius slices: slices capStart: true capEnd: true
]

{ #category : #adding }
WDCGenericMeshBuilder >> addPolyLineWithPoints: points colors: colors radius: radius slices: slices capStart: capStart capEnd: capEnd [
	points size < 2 ifTrue: [ ^ self ].

	self buildCylinderWithSegments: points size slices: slices
		capStart: capStart capEnd: capEnd
		segmentRadiusWith: [:index | radius]
		segmentCenterWith: [:index | points at: index]
		segmentDirectionBlock: [:index |
			| previous next |
			previous := points at: (index - 1 max: 1).
			next := points at: (index + 1 min: points size).
			next - previous
		]
		segmentColorBlock: [:index | colors at: index ]
]

{ #category : #adding }
WDCGenericMeshBuilder >> addPolyLineWithPoints: points radius: radius slices: slices [
	^ self addPolyLineWithPoints: points radius: radius slices: slices capStart: true capEnd: true

]

{ #category : #adding }
WDCGenericMeshBuilder >> addPolyLineWithPoints: points radius: radius slices: slices capStart: capStart capEnd: capEnd [
	points size < 2 ifTrue: [ ^ self ].

	self buildCylinderWithSegments: points size slices: slices
		capStart: capStart capEnd: capEnd
		segmentRadiusWith: [:index | radius]
		segmentCenterWith: [:index | points at: index ]
		segmentDirectionBlock: [:index |
			| previous next |
			previous := points at: (index - 1 max: 1).
			next := points at: (index + 1 min: points size).
			next - previous
		]
		segmentColorBlock: [:index | currentColor]
]

{ #category : #adding }
WDCGenericMeshBuilder >> addQuadI1: i1 i2: i2 i3: i3 i4: i4 [
	self addI1: i1 i2: i2 i3: i3.
	self addI1: i3 i2: i4 i3: i1
]

{ #category : #adding }
WDCGenericMeshBuilder >> addUVSphereRadius: radius segments: segments slices: slices [
	| normal position texcoord phi theta x y z firstRow secondRow firstSlice secondSlice |
	self beginTriangles.

	"Add the vertices"
	(0 to: segments - 1) do: [ :segment |
		phi := (Float pi * segment) / (segments - 1).
		
		(0 to: slices - 1) do: [ :slice |
			theta := (Float twoPi  * slice) / (slices - 1).
			x := (theta cos) * (phi sin ).
			y := (theta sin) * (phi sin ).
			z := phi cos.
			normal := Float32x3 x: x y: y z: z.
			position := Float32x3 x: (x * radius) y: (y * radius) z: (z * radius).			
			texcoord := Float32x2 x: theta / Float twoPi y: phi / Float pi.
			self addP: position N: normal  TC: texcoord.
		].		
	].

	"Add the quads"
	(0 to: segments - 2) do: [ :segment |
		firstRow := segment*slices.
		secondRow := (segment+1)*slices.
		(0 to: slices - 1) do: [ :slice |
			firstSlice := slice + 1.
			secondSlice := (slice + 1) % slices + 1.
			self addQuadI1: firstRow + secondSlice i2: firstRow+firstSlice i3: secondRow+firstSlice i4: secondRow+secondSlice
		]
	].

]

{ #category : #adding }
WDCGenericMeshBuilder >> addWireCubeWithWidth: width height: height depth: depth [
	| px py pz nx ny nz |
	self beginLines.
	
	px := width * 0.5.
	py := height * 0.5.
	pz := depth * 0.5.
	nx := width * -0.5.
	ny := height * -0.5.
	nz := depth * -0.5.
	
	self
		addP: (Float32x3 x: nx y: ny z: nz);
		addP: (Float32x3 x: px y: ny z: nz);
		addP: (Float32x3 x: nx y: py z: nz);
		addP: (Float32x3 x: px y: py z: nz);
		
		addP: (Float32x3 x: nx y: ny z: pz);
		addP: (Float32x3 x: px y: ny z: pz);
		addP: (Float32x3 x: nx y: py z: pz);
		addP: (Float32x3 x: px y: py z: pz).
		
	self
		addI1: 1 i2: 2;
		addI1: 3 i2: 4;
		addI1: 5 i2: 6;
		addI1: 7 i2: 8;
		
		addI1: 1 i2: 3;
		addI1: 2 i2: 4;
		addI1: 5 i2: 7;
		addI1: 6 i2: 8;
	
		addI1: 1 i2: 5;
		addI1: 2 i2: 6;
		addI1: 3 i2: 7;
		addI1: 4 i2: 8.

]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> beginLines [
	self
		beginSubMeshWith: AGPU_LINES material: currentMaterial;
		beginWithNewBaseVertex
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> beginSubMeshWith: primitiveType material: newMaterial [
	| submesh last |
	submeshes ifNotEmpty: [ 
		last := submeshes last.
		"Avoid adding submeshes."
		((last primitiveType) = primitiveType and: [ last material == newMaterial ]) ifTrue: [ ^ self ].
		self finishSubmesh
	].
	submesh := self createSubmeshObject.
	
	submesh primitiveType: primitiveType;
			material: newMaterial;
			firstIndex: indices size.
	submeshes add: submesh
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> beginTriangles [
	self
		beginSubMeshWith: AGPU_TRIANGLES material: currentMaterial;
		beginWithNewBaseVertex
]

{ #category : #public }
WDCGenericMeshBuilder >> beginWithNewBaseVertex [
	baseVertex := vertices size.
]

{ #category : #adding }
WDCGenericMeshBuilder >> buildCylinderWithSegments: segments slices: slices capStart: capStart capEnd: capEnd
segmentRadiusWith: radiusBlock segmentCenterWith: segmentCenterBlock segmentDirectionBlock: segmentDirectionBlock segmentColorBlock: segmentColorBlock [
	| firstRow secondRow firstSlice secondSlice lastSegmentDirection lastSegmentOrientation firstSegmentOrientation firstSegmentRadius firstSegmentCenter lastSegmentRadius lastSegmentCenter lastSegmentOrientationMatrix firstSegmentColor lastSegmentColor |
	self beginTriangles.

	"Add the vertices"
	lastSegmentDirection := Float32x3 y: 1.0.
	lastSegmentOrientation := QuaternionF32 identity.	
	firstSegmentOrientation := lastSegmentOrientation.
	1 to: segments do: [ :segmentIndex  |
		| radius center direction color orientationDelta orientation |
		radius := radiusBlock cull: segmentIndex.
		center := segmentCenterBlock cull: segmentIndex.
		direction := segmentDirectionBlock cull: segmentIndex.
		color := segmentColorBlock cull: segmentIndex.
		orientationDelta := QuaternionF32 rotationFromVector: lastSegmentDirection into: direction.
		
		lastSegmentDirection := direction.
		lastSegmentOrientation := orientationDelta * lastSegmentOrientation.
		lastSegmentOrientationMatrix := orientation := lastSegmentOrientation asFloat32x3x3.
		
		segmentIndex = 1 ifTrue: [
			firstSegmentOrientation := orientation.
			firstSegmentRadius := radius.
			firstSegmentCenter := center.
			firstSegmentColor := color.
		].
		lastSegmentRadius := radius.
		lastSegmentCenter := center.
		lastSegmentColor := color.

		0 to: slices - 1 do: [ :slice |
			| position phi |
			phi := (Float twoPi  * slice) / (slices - 1).
			position := orientation * (Float32x3 x: phi cos * radius y: 0 z: phi sin * radius) + center.
			self addP: position C: color.
		].		
	].

	"Add the quads"
	0 to: segments - 2 do: [ :segment |
		firstRow := segment*slices.
		secondRow := (segment+1)*slices.
		0 to: slices - 1 do: [ :slice |
			firstSlice := slice + 1.
			secondSlice := (slice + 1) % slices + 1.
			self addQuadI1: firstRow + secondSlice i2: firstRow+firstSlice i3: secondRow+firstSlice i4: secondRow+secondSlice.
		]
	].

	"Add the caps"
	capStart ifTrue: [ 
		self addCircleCenter: firstSegmentCenter radius: firstSegmentRadius slices: slices orientation: firstSegmentOrientation color: firstSegmentColor isTop: false.
	].
	capEnd ifTrue: [
		self addCircleCenter: lastSegmentCenter radius: lastSegmentRadius slices: slices orientation: lastSegmentOrientationMatrix color: lastSegmentColor isTop: true.
	]
]

{ #category : #accessing }
WDCGenericMeshBuilder >> clear [
	super clear.
	vertices removeAll.
	indices removeAll.
	submeshes removeAll.
	baseVertex := 0.
	currentColor := Color white asFloat32x4.
	boundingBox := BoxF32 empty.
	lastUsedVertexForCollision := 0.
]

{ #category : #accessing }
WDCGenericMeshBuilder >> color: aMaterial [
	self currentColor: aMaterial
]

{ #category : #'display box access' }
WDCGenericMeshBuilder >> computeBoundingBox [
	boundingBox := BoxF32 empty.
	vertices do: [ :vertex | boundingBox insertPoint: vertex position asFloat32x3 ]
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> computeNormals [
	self finishSubmesh.
	vertices do: [ :each | each normal: Float32x3 zeros ].
	submeshes do: [ :sm | self computeNormalsFor: sm].
	vertices do: [ :each | each normal: each normal normalized ].
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> computeNormalsFor: submesh [
	| triangleCount indexBase i1 i2 i3 |
	submesh primitiveType ~= AGPU_TRIANGLES ifTrue: [ ^ self ].
	triangleCount := submesh indexCount // 3.

	indexBase := submesh firstIndex.	
	i1 := indexBase + 1.
	i2 := indexBase + 2.
	i3 := indexBase + 3.
	1 to: triangleCount do: [ :ti |
		| vi1 vi2 vi3 p1 p2 p3 u v v1 v2 v3 n |
		vi1 := (indices at: i1) + 1.
		vi2 := (indices at: i2) + 1.
		vi3 := (indices at: i3) + 1.
		
		v1 := vertices at: vi1.
		v2 := vertices at: vi2.
		v3 := vertices at: vi3.
		
		p1 := v1 position asFloat32x3.
		p2 := v2 position asFloat32x3.
		p3 := v3 position asFloat32x3.

		u := p2 - p1.
		v := p3 - p1.
		n := u cross: v.
		
		v1 normal: v1 normal + n.
		v2 normal: v2 normal + n.
		v3 normal: v3 normal + n.

		i1 := i1 + 3.
		i2 := i2 + 3.
		i3 := i3 + 3.
	].

]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> computeTangentsBitangents [
	| vertexCount vertex normal tangent bitangent tangents bitangents scaleFactor |
	self finishSubmesh.
	vertexCount := vertices size.
	tangents := Array new: vertexCount withAll: Float32x3 zeros.
	bitangents := Array new: vertexCount withAll: Float32x3 zeros.
	submeshes do: [ :sm | self computeTangentsBitangentsFor: sm tangents: tangents bitangents: bitangents ].
	
	1 to: vertexCount do: [ :vi |
		vertex := (vertices at: vi).
		
		normal := vertex normal asFloat32x3.
		tangent := tangents at: vi.
		bitangent := bitangents at: vi.
		
		"Gram schmidth orthogonalization"
		tangent := (tangent - (normal * (normal dot: tangent))) normalized.
		bitangent := (bitangent - (normal * (normal dot: bitangent)) - (tangent * (tangent dot: bitangent))) normalized.
		scaleFactor := (normal cross: tangent) dot: bitangent.
		vertex tangent4: (Float32x4 x: tangent x y: tangent y z: tangent z w: scaleFactor).
		
		vertices at: vi put: vertex.
	].

]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> computeTangentsBitangentsFor: submesh tangents: tangents bitangents: bitangents [
	| triangleCount indexBase i1 i2 i3 vi1 vi2 vi3 p1 p2 p3 u v tc1 tc2 tc3 det den tangent bitangent v1 v2 v3 du1 dv1 du2 dv2 |
	submesh primitiveType ~= AGPU_TRIANGLES ifTrue: [ ^ self ].
	triangleCount := submesh indexCount // 3.

	indexBase := submesh firstIndex.	
	i1 := indexBase + 1.
	i2 := indexBase + 2.
	i3 := indexBase + 3.
	1 to: triangleCount do: [ :ti |
		vi1 := (indices at: i1) + 1.
		vi2 := (indices at: i2) + 1.
		vi3 := (indices at: i3) + 1.
		
		p1 := (vertices at: vi1) position asFloat32x3.
		p2 := (vertices at: vi2) position asFloat32x3.
		p3 := (vertices at: vi3) position asFloat32x3.

		tc1 := (vertices at: vi1) texcoord.
		tc2 := (vertices at: vi2) texcoord.
		tc3 := (vertices at: vi3) texcoord.

		u := p2 - p1.
		v := p3 - p1.
		
		du1 := tc2 x - tc1 x.
		dv1 := tc2 y - tc1 y.
		
		du2 := tc3 x - tc1 x.
		dv2 := tc3 y - tc1 y.
		
		det := (du1*dv2) - (du2*dv1).
		(det closeTo: 0.0) ifFalse: [ 
			den := 1.0 / det.
			
			tangent := (u * (den*dv2))  - (v * (den*dv1)).
			bitangent := (v * (den*du1)) - (u * (den*du2)).
			
			v1 := vertices at: vi1.
			v2 := vertices at: vi2.
			v3 := vertices at: vi3.
			
			tangents at: vi1 put: (tangents at: vi1) + tangent.
			tangents at: vi2 put: (tangents at: vi2) + tangent.
			tangents at: vi3 put: (tangents at: vi3) + tangent.

			bitangents at: vi1 put: (bitangents at: vi1) + bitangent.
			bitangents at: vi2 put: (bitangents at: vi2) + bitangent.
			bitangents at: vi3 put: (bitangents at: vi3) + bitangent.
		].
				
		i1 := i1 + 3.
		i2 := i2 + 3.
		i3 := i3 + 3.
	].

]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> createIndexBuffer [
	^ engine createIndex: 4 elements: indices size immutableBuffer: indices asByteArray 
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> createMeshWithSubmeshes: newSubmeshes [
	| mesh |
	self computeBoundingBox.
	mesh := self instantiateMesh.
	mesh
		boundingBox: boundingBox;
		vertexData: vertexData;
		vertexBinding: self createVertexBinding;
		indexBuffer: self createIndexBuffer;
		submeshes: newSubmeshes.
	^ mesh
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> createSubmeshObject [
	^ WDCGenericSubmesh new.
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> createVertexBinding [
	^ vertexData createVertexBindingFor: engine
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> createVertexBuffer [
	^ vertexData createVertexBufferFor: engine
]

{ #category : #initialization }
WDCGenericMeshBuilder >> createVertexData [
	vertexData := WDCMeshInterleavedVertexData new
		data: vertices;
		vertexClass: self vertexClass;
		yourself. 
]

{ #category : #accessing }
WDCGenericMeshBuilder >> currentColor [
	^ currentColor
]

{ #category : #accessing }
WDCGenericMeshBuilder >> currentColor: aColorOrFloat32x4 [
	currentColor := aColorOrFloat32x4 asFloat32x4
]

{ #category : #accessing }
WDCGenericMeshBuilder >> currentMaterial [
	^ currentMaterial
]

{ #category : #accessing }
WDCGenericMeshBuilder >> currentMaterial: anObject [
	currentMaterial := anObject
]

{ #category : #accessing }
WDCGenericMeshBuilder >> defaultMaterial [
	currentMaterial := engine defaultMaterial
]

{ #category : #accessing }
WDCGenericMeshBuilder >> engine [
	^ engine
]

{ #category : #accessing }
WDCGenericMeshBuilder >> engine: anEngine [
	engine := anEngine ifNil: [WDCDummyEngine new].
	currentMaterial ifNil: [ self defaultMaterial ]
]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> finishSubmesh [
	| last |
	submeshes ifEmpty: [ ^ self ].
	last := submeshes last.
	last indexCount: indices size - last firstIndex.
]

{ #category : #initialization }
WDCGenericMeshBuilder >> initialize [
	super initialize.
	engine := WDCDummyEngine new.
	vertices := StdnVector newFor: self vertexClass.
	indices := StdnVector newFor: Int32.
	self createVertexData.
	boundingBox := BoxF32 empty.
	submeshes := OrderedCollection new.
	baseVertex := 0.
	currentColor := Color white asFloat32x4.
	lastUsedVertexForCollision := 0.

]

{ #category : #'as yet unclassified' }
WDCGenericMeshBuilder >> instantiateMesh [
	^ WDCGenericMesh new
]

{ #category : #accessing }
WDCGenericMeshBuilder >> material: aMaterial [
	self currentMaterial: aMaterial
]

{ #category : #accessing }
WDCGenericMeshBuilder >> mesh [
	vertices ifEmpty: [ ^ WDCNullRenderable new ].
	indices ifEmpty: [ ^ WDCNullRenderable new ].
	self finishSubmesh.
	
	^ self createMeshWithSubmeshes: submeshes asArray.
]

{ #category : #accessing }
WDCGenericMeshBuilder >> useDefaultMaterial [
	self currentMaterial: engine resourceCache defaultMaterial
]

{ #category : #accessing }
WDCGenericMeshBuilder >> useFlatColorMaterial [
	self currentMaterial: engine resourceCache flatColorMaterial
]

{ #category : #initialization }
WDCGenericMeshBuilder >> vertexClass [
	^ vertexClass ifNil: [ vertexClass := WDCGenericVertexF32 ]
]
