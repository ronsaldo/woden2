Class {
	#name : #WDCSceneRenderingShaderSignature,
	#superclass : #WDCShaderSignature,
	#instVars : [
		'defaultSamplers',
		'defaultSamplersSession'
	],
	#category : #'WodenEngine-Core-Shaders'
}

{ #category : #'as yet unclassified' }
WDCSceneRenderingShaderSignature class >> signatureSpec: spec [
	"
	self rebuildShaderSignatureMethods
	"
	spec
		name: #ForwardRenderer;
		bank: #Samplers with: [ :bank |
			bank
				maxBindings: 10;
				sampler: #Samplers count: 6
		];
		bank: #CameraState with: [ :bank |
			bank
				maxBindings: 1000;
				uniform: #ObjectState;
				storage: #PostProcessingState
		];
		bank: #LightingState with: [ :bank |
			bank
				maxBindings: 1000;
				uniform: #GlobalLightingState;
				texture: #SpotShadowMaps count: 1;
				texture: #PointShadowMaps count: 1;
				texture: #AmbientOcclusion count: 1;
				texture: #SpecularBRDFLut count: 1;
				texture: #DiffuseIrradianceMap count: 1;
				texture: #SpecularIrradianceMap count: 1
		];
		bank: #ObjectState with: [ :bank |
			bank
				maxBindings: 100000;
				uniform: #ObjectState;
				storage: #InstanceObjectState
		];
		bank: #RenderableState with: [ :bank |
			bank
				maxBindings: 10000;
				storage: #AnimationState;
				texture: #Textures count: 2
		];
		bank: #MaterialState with: [ :bank |
			bank
				maxBindings: 10000;
				uniform: #Attributes;
				storage: #BigAttributes;
				texture: #Textures count: 20
		];
		yourself
]

{ #category : #'as yet unclassified' }
WDCSceneRenderingShaderSignature >> activeOnStateTracker: stateTracker [
	super activeOnStateTracker: stateTracker.
	stateTracker useShaderResources: self defaultSamplers.
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> createHandleForDevice: device [
	^ device createShaderSignatureBuilder

		"Samplers"
		beginBindingBank: 10;
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLER bindingPointCount: 6; "Samplers"

		"CameraState"
		beginBindingBank: 1000;
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_UNIFORM_BUFFER bindingPointCount: 1; "ObjectState"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_STORAGE_BUFFER bindingPointCount: 1; "PostProcessingState"

		"LightingState"
		beginBindingBank: 1000;
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_UNIFORM_BUFFER bindingPointCount: 1; "GlobalLightingState"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 1; "SpotShadowMaps"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 1; "PointShadowMaps"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 1; "AmbientOcclusion"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 1; "SpecularBRDFLut"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 1; "DiffuseIrradianceMap"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 1; "SpecularIrradianceMap"

		"ObjectState"
		beginBindingBank: 100000;
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_UNIFORM_BUFFER bindingPointCount: 1; "ObjectState"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_STORAGE_BUFFER bindingPointCount: 1; "InstanceObjectState"

		"RenderableState"
		beginBindingBank: 10000;
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_STORAGE_BUFFER bindingPointCount: 1; "AnimationState"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 2; "Textures"

		"MaterialState"
		beginBindingBank: 10000;
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_UNIFORM_BUFFER bindingPointCount: 1; "Attributes"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_STORAGE_BUFFER bindingPointCount: 1; "BigAttributes"
			addBindingBankElement: AGPU_SHADER_BINDING_TYPE_SAMPLED_IMAGE bindingPointCount: 20; "Textures"

		build

]

{ #category : #accessing }
WDCSceneRenderingShaderSignature >> defaultSamplers [
	| samplerDesc bindings |
	(defaultSamplersSession == Smalltalk session and: [ defaultSamplers isNotNil ]) ifTrue: [ ^ defaultSamplers ].
	
	samplerDesc := AGPUSamplerDescription new
		address_u: AGPU_TEXTURE_ADDRESS_MODE_WRAP;
		address_v: AGPU_TEXTURE_ADDRESS_MODE_WRAP;
		address_w: AGPU_TEXTURE_ADDRESS_MODE_WRAP;
		max_lod: 10000.0;
		yourself.
	engine setupAnisotropicSampler: samplerDesc.
		
	bindings := self newSamplers.
	bindings
		createSampler: 0 description: samplerDesc;
		createSampler: 1 description: samplerDesc.
		
	samplerDesc := AGPUSamplerDescription new
		address_u: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		address_v: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		address_w: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		max_lod: 10000.0;
		yourself.
	engine setupAnisotropicSampler: samplerDesc.
	bindings
		createSampler: 2 description: samplerDesc.

	samplerDesc := AGPUSamplerDescription new
		address_u: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		address_v: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		address_w: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		comparison_enabled: 1;
		comparison_function: AGPU_GREATER;
		max_lod: 10000.0;
		yourself.
	engine setupAnisotropicSampler: samplerDesc.
	bindings
		createSampler: 3 description: samplerDesc.

	samplerDesc := AGPUSamplerDescription new
		address_u: AGPU_TEXTURE_ADDRESS_MODE_BORDER;
		address_v: AGPU_TEXTURE_ADDRESS_MODE_BORDER;
		address_w: AGPU_TEXTURE_ADDRESS_MODE_BORDER;
		max_lod: 10000.0;
		yourself.
	engine setupAnisotropicSampler: samplerDesc.
	bindings
		createSampler: 4 description: samplerDesc.

	"IBL BRDF Lookup function"
	samplerDesc := AGPUSamplerDescription new
		address_u: AGPU_TEXTURE_ADDRESS_MODE_CLAMP ;
		address_v: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		address_w: AGPU_TEXTURE_ADDRESS_MODE_CLAMP;
		max_lod: 10000.0;
		yourself.
	engine setupAnisotropicSampler: samplerDesc.
	bindings
		createSampler: 5 description: samplerDesc.

	defaultSamplersSession := Smalltalk session.
	^ defaultSamplers := bindings
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> newCameraState [
	^ engine createShaderSignature: self resourceBinding: 1 elements: 2
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> newLightingState [
	^ engine createShaderSignature: self resourceBinding: 2 elements: 7
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> newMaterialState [
	^ engine createShaderSignature: self resourceBinding: 5 elements: 22
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> newObjectState [
	^ engine createShaderSignature: self resourceBinding: 3 elements: 2
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> newRenderableState [
	^ engine createShaderSignature: self resourceBinding: 4 elements: 3
]

{ #category : #'generated shader signature methods' }
WDCSceneRenderingShaderSignature >> newSamplers [
	^ engine createShaderSignature: self resourceBinding: 0 elements: 6
]
