PI = Math.PI

class @Photosphere 
	constructor: (@image, method, @camOffset) -> 
		@extrapolator = if method is 'quaternions'
			new Extrapolator_Quaternions()
		else 
			new Extrapolator_Euler()
		# @$iframe = $('<iframe width="284" height="170" src="//www.youtube.com/embed/72RqpItxd8M&autoplay=1" frameborder="0"></iframe>')
		# 	.css
		# 		position: 'absolute'
		# 		top:0
		# 		left:0
		@$iframe = $('<div id="hola"> HOLA </div>').css
				position: 'absolute'
				top:0
				left:0
				width: 100
				height: 100
				fontSize: 40
				border: '1px dashed grey'
				background: 'rgba(0,100,0,.5)'
		@css3DObject = new THREE.CSS3DObject( @$iframe[0] )
		@css3DObject.position.z = -500

	loadPhotosphere: (holder) ->
		holder.innerHTML = 'wait...'
		@holder = holder
		self = this
		
		new THREE.TextureLoader().load @image, (texture) =>
			#texture.offset = new THREE.Vector2(@exif.x / @exif.full_height, @exif.y / @exif.full_width)
			material = new THREE.MeshBasicMaterial(
				map: texture
				overdraw: true
			)
			@start3D(null,material)
		@test = 3
		
		return

	canDoWebGL: ->
		
		# Modified mini-Modernizr
		# https://github.com/Modernizr/Modernizr/blob/master/feature-detects/webgl-extensions.js
		canvas = undefined
		ctx = undefined
		exts = undefined
		try
			canvas = document.createElement('canvas')
			ctx = canvas.getContext('webgl') or canvas.getContext('experimental-webgl')
			exts = ctx.getSupportedExtensions()
		catch e
			return false
		if ctx is `undefined`
			false
		else
			true

	start3D: (image,material) ->
		alert 'Please make sure three.js is loaded'  unless window['THREE']?
		
		# Start Three.JS rendering

		@camera = new THREE.PerspectiveCamera(50, parseInt(@holder.offsetWidth) / parseInt(@holder.offsetHeight), 1, 1100)
		@scene = new THREE.Scene()
		mesh = new THREE.Mesh(
			new THREE.SphereGeometry(500, 32, 32),
			if material? then material else @loadTexture(image)
		)
		mesh.scale.x = -1
		@scene.add mesh
		
		# Check for WebGL
		if @canDoWebGL()
			# This is for nice browsers + computers
			try
				@renderer = new THREE.WebGLRenderer()
				@maxSize = @renderer.context.getParameter(@renderer.context.MAX_TEXTURE_SIZE)
			catch e
				@renderer = new THREE.CanvasRenderer()
		else
			@renderer = new THREE.CanvasRenderer()
		@renderer.setSize parseInt(@holder.offsetWidth), parseInt(@holder.offsetHeight)
		@holder.innerHTML = ''
		$(@renderer.domElement).css
			position: 'absolute'
			top: 0
		@holder.appendChild @renderer.domElement


		#----------
		@cssScene = new THREE.Scene()

		
		@cssScene.add(@css3DObject);
		@cssRenderer = new THREE.CSS3DRenderer();
		@cssRenderer.setSize  parseInt(@holder.offsetWidth), parseInt(@holder.offsetHeight)
		$(@cssRenderer.domElement).css
			position: 'absolute'
			top: 0
		@holder.appendChild @cssRenderer.domElement


		#----------

		self = this
		@holder.addEventListener 'click', ((event) =>
			@test = ( @test + 1 ) % 10
			#4 10 16 22 28 34
			$('#goForIt').text( @test)
		), false
		# @holder.addEventListener 'touchstart', ((event) =>
		# 	self.onDocumentTouchStart event, self
		# 	return
		# ), false
		
		window.addEventListener 'deviceorientation', (event) =>
	        @onDeviceOrientation event
	    do mainLoop = =>
		    window.webkitRequestAnimationFrame (t) =>
		    	@tick t
		    	mainLoop()

		$(document).on 'touchmove', (event)=>
			newY = event.originalEvent?.touches?[0]?.pageY or event.pageY
			@lastY ?= newY
			delta = newY - @lastY
			@lastY = newY
			
			proposed = @camera.fov - delta * 0.05
			if proposed > 10 and proposed < 100
				@camera.fov = proposed
				@camera.updateProjectionMatrix()
				event.preventDefault()
		$(document).on 'touchstart mousedown', (event)=>
			@lastY = event.originalEvent?.touches?[0]?.pageY or event.pageY
		return


	onWindowResize: (self) ->
		self.camera.aspect = parseInt(self.holder.offsetWidth) / parseInt(self.holder.offsetHeight)
		self.camera.updateProjectionMatrix()
		self.renderer.setSize parseInt(self.holder.offsetWidth), parseInt(self.holder.offsetHeight)
		#self.render()
		return

	onMouseWheel: (event, self) ->
		proposed = self.camera.fov - event.wheelDeltaY * 0.05
		if proposed > 10 and proposed < 100
			self.camera.fov = proposed
			self.camera.updateProjectionMatrix()
			self.render()
			event.preventDefault()
		return

	
	onDeviceOrientation: (event) ->
		@extrapolator.onDeviceOrientation(event)
		@lastT = +new Date();

	tick: () ->
		return unless @lastT?
		@css3DDir ?= 1
		@css3DObject.position.z = @css3DObject.position.z += @css3DDir
		if @css3DObject.position.z < -500 then @css3DDir *= -1
		if @css3DObject.position.z > 500 then @css3DDir *= -1
		@guess = @extrapolator.extrapolate( new Date() - @lastT )
		@rotateSphere(@guess)

	rotateSphere: (euler)->
		
		#debugger
		m = new THREE.Matrix4()
		if navigator.userAgent.match(/Android/i)
			euler = new THREE.Euler(euler.x, euler.y, euler.z, 'ZXY') #celu
		else 
			euler = new THREE.Euler(euler.x, euler.y, euler.z, 'ZYX') #chrome
		
		m.makeRotationFromEuler(euler)
			
		if landscape = yes
			#esto es para landscape porque se rotan los ejes 
			m1 = new THREE.Matrix4()
			m1.makeRotationZ(-PI/2)
			m.multiply m1
	
		# para adelante en la foto es para abajo con el celu, asi que corrijo
		#aca todo bien en portrait
		m1 = new THREE.Matrix4().makeRotationX(-PI/2)
		m2 = new THREE.Matrix4().makeTranslation(@camOffset,0,0)
		m = m1.multiply m
		m = m.multiply m2

		
		
		@camera.matrixAutoUpdate = no
		@camera.matrixWorld = m
		@renderer.render @scene, @camera
		@cssRenderer.render @cssScene, @camera
		#@scene.updateMatrixWorld()
		#
		# AxB, B rota primero
		# cuando quiero rotar lo que veo sin rotar los sensores multiplico m*m1, cuando quiero con sensores m=m1*m

		return