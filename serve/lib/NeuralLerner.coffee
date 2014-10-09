
class @NeuralLerner
	constructor: () ->
		
	# neural network foo --------------------------------------------
	buildInputArray: (deltaT, axis)->
		#return if deltaT > 100
		extrapolation = @extrapolate(deltaT)
		inputArray = []

		# the neural network should know about the elapsed time
		inputArray.push deltaT
		# the extrapolation is usually right so it should also be useful
		inputArray.push extrapolation[axis]
		# also the influence of every individual derivative should be important
		i_factorial = 1
		inputArray.push rates[0][axis]
		for i in [1...rates.length]
			inputArray.push rates[i][axis]
			i_factorial *= i
			inputArray.push rates[i][axis] * Math.pow(deltaT, i) / i_factorial
		return inputArray
	
	lernPoint: (old_rates, rates, deltaT)->
		# rates & old_rates are arrays with velocity, acceleration, etc
		unless @neuralNet?
			@neuralNet = new convnetjs.Net()
			@neuralNet.makeLayers [
				{type: "input", out_sx: 1, out_sy: 1, out_depth: old_rates.length}
				{type: "fc", num_neurons: 10, activation: "sigmoid"}
				{type: "fc", num_neurons: 10, activation: "sigmoid"}
				{type: "fc", num_neurons: 10, activation: "sigmoid"}
				{type: "regression", num_neurons: rates.length}
			]

			@trainer = new convnetjs.SGDTrainer(@neuralNet,
				learning_rate: 0.05
				momentum: 0.01
				batch_size: 1
				l2_decay: 0.001
			)
		inputArray = @buildInputArray old_rates, deltaT, axis
		# train on this datapoint, saying [0.5, -1.3] should map to value 0.7:
		# note that in this case we are passing it a list, because in general
		# we may want to  regress multiple outputs and in this special case we 
		# used num_neurons:1 for the regression to only regress one.
		@trainer.train (new convnetjs.Vol(old_rates)), rates]

	neuralExtrapolate: (rates, deltaT)->	
		# evaluate on a datapoint. We will get a 1x1x1 Vol back, so we get the
		# actual output by looking into its 'w' field:
		# (whatever, the example said so...)
		extrapolation = new THREE.Vector3()

		for axis in 'xyz'
			inputArray = @buildInputArray @rates, deltaT, axis
			vol = new convnetjs.Vol(inputArray)
			predicted_values = @neuralNet.forward(vol)
			extrapolation[axis] = predicted_values.w[0]

			# todo: try predicting the tree axis at once instead of treating every axis as if it were the same one	
			# this may work because the neural network might find relationships between them
		return extrapolation
	# end neural network foo --------------------------------------------