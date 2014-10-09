# I Override the THREE.js optimizations because they brake my algorithms
THREE.Quaternion::slerp = (qb, t) ->
  x = @_x
  y = @_y
  z = @_z
  w = @_w
  
  # http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/
  cosHalfTheta = w * qb._w + x * qb._x + y * qb._y + z * qb._z
  if cosHalfTheta < 0
    @_w = -qb._w
    @_x = -qb._x
    @_y = -qb._y
    @_z = -qb._z
    cosHalfTheta = -cosHalfTheta
  else
    @copy qb
  if cosHalfTheta >= 1.0
    @_w = w
    @_x = x
    @_y = y
    @_z = z
    return this
  halfTheta = Math.acos(cosHalfTheta)
  sinHalfTheta = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta)

  #remove this optimization as it breakes my code
  if no and Math.abs(sinHalfTheta) < 0.001 
    @_w = 0.5 * (w + @_w)
    @_x = 0.5 * (x + @_x)
    @_y = 0.5 * (y + @_y)
    @_z = 0.5 * (z + @_z)
    return this
  ratioA = Math.sin((1 - t) * halfTheta) / sinHalfTheta
  ratioB = Math.sin(t * halfTheta) / sinHalfTheta
  @_w = (w * ratioA + @_w * ratioB)
  @_x = (x * ratioA + @_x * ratioB)
  @_y = (y * ratioA + @_y * ratioB)
  @_z = (z * ratioA + @_z * ratioB)
  @onChangeCallback()
  return this

PI = Math.PI
eulerOrder = 
	if navigator.userAgent.match(/Android/i) then 'ZXY' #celu
	else 'ZYX' #celu

class @Extrapolator_Quaternions
	constructor: (@grade = 2) ->
		
	onDeviceOrientation: (event) ->
		alpha = (event.alpha-180) / 180*PI
		beta  = event.beta  / 180*PI
		gamma = event.gamma / 180*PI
		euler = new THREE.Euler(beta, gamma, alpha, 'ZXY') #celu
		
		@old_rates ?= (new THREE.Quaternion() for quat in [0..@grade])
		@rates ?= (new THREE.Quaternion() for quat in [0..@grade])
		
		now = event.t or +new Date()

		@lastT ?= now
		deltaT = now - @lastT

		[@old_rates, @rates] = [@rates, @old_rates]


		@rates[0].setFromEuler(euler)

		for i in [1...@rates.length]
			# d = quaternion que va desde q hasta r
			q = @old_rates[i-1]
			qConj = new THREE.Quaternion().copy(q).inverse()
			r = @rates[i-1]
			d = new THREE.Quaternion().copy(r).multiply(qConj)
			@rates[i] = new THREE.Quaternion().slerp(d, 1/deltaT)
			# Here I am just computing the taylor expansion f(t+dt) = f(t) + ... + f^n(t) * dt^n / n!
		@lastT = now

		#@lernPoint @old_rates, @rates, deltaT


	extrapolate: (deltaT) ->
		return unless @rates?

		deltaT = 200 if deltaT > 200

		extrapolation = new THREE.Quaternion().copy @rates[0]
		i_factorial = 1
		
		for i in [1...@rates.length]
			i_factorial *= i
			factor = Math.pow(deltaT, i) / i_factorial
			rate = new THREE.Quaternion().slerp(@rates[i], factor)
			rate.multiply extrapolation
			extrapolation = rate
			#extrapolation.multiply rate
		euler = new THREE.Euler().setFromQuaternion(extrapolation, 'ZXY')
		return new THREE.Vector3(euler.x, euler.y, euler.z)
		return extrapolation

	extrapolateToEulerDeg: (deltaT) ->
		ex = @extrapolate(deltaT)

		return beta: ex.x / PI * 180, gamma: ex.y / PI * 180, alpha: ex.z / PI * 180, t: @lastT + deltaT