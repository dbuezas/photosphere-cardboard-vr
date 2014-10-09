PI = Math.PI
eulerOrder = 
	if navigator.userAgent.match(/Android/i) then 'ZXY' #celu
	else 'ZYX' #celu

class @Extrapolator_Euler
	constructor: (@grade = 1)->
		
	onDeviceOrientation: (event)->
		beta  = event.beta  / 180*PI
		gamma = event.gamma / 180*PI
		alpha = (event.alpha-180) / 180*PI
		
		@old_rates ?= (new THREE.Vector3() for vector in [0..@grade])
		@rates ?= (new THREE.Vector3() for vector in [0..@grade])
		

		[@old_rates, @rates] = [@rates, @old_rates]

		now = event.t or + new Date()

		@lastT ?= now
		deltaT = now - @lastT


		@rates[0].set(beta, gamma, alpha) 

		for i in [1...@rates.length]
			@rates[i]
				.copy(@rates[i-1])
				.sub(@old_rates[i-1])
				.divideScalar(deltaT)

		@lastT = now

	extrapolate: (deltaT) ->
		return unless @rates?

		deltaT = 100 if deltaT > 100
		#deltaT = 20 if deltaT > 20
		extrapolation = new THREE.Vector3()
		extrapolation
			.copy @rates[0]
		i_factorial = 1
		
		for i in [1...@rates.length]
			i_factorial *= i
			rate = new THREE.Vector3()
				.copy(@rates[i])
				.multiplyScalar( Math.pow(deltaT, i) )
				.divideScalar( i_factorial)
			extrapolation.add rate
		return extrapolation
	extrapolateToEulerDeg: (deltaT) ->
		ex = @extrapolate(deltaT)

		return beta: ex.x / PI * 180, gamma: ex.y / PI * 180, alpha: ex.z / PI * 180, t: @lastT + deltaT
		 
