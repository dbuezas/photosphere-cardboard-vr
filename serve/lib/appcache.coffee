
applicationCache.addEventListener "updateready", ->
	if window.applicationCache.status is window.applicationCache.UPDATEREADY
		window.applicationCache.swapCache()
		window.location.reload()
applicationCache.addEventListener "obsolete", ->
	window.applicationCache.update()
