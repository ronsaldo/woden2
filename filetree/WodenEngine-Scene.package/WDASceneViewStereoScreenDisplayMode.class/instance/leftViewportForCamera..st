multi eye rendering
leftViewportForCamera: camera
	| cameraState |
	cameraState := WTCameraState new.
	cameraState
		projectionMatrix: leftProjectionMatrix.
	
	^ WTSViewport new
		camera: camera;
		cameraState: cameraState;
		renderTarget: leftRenderTarget;
		resolveRenderTarget: leftResolveRenderTarget;
		bounds: leftRenderTarget bounds;
		cameraTransformFunction: [ :ct | ct transformTransform: self leftCameraTransform ];
		submode: #full