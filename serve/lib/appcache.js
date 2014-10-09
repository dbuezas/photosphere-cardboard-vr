
applicationCache.onupdateready = function() {
  document.body.innerHTML = "app cache updated. will reload.";
  if (window.applicationCache.status === window.applicationCache.UPDATEREADY) {
    window.applicationCache.swapCache();
    return window.location.reload();
  }
};

applicationCache.onobsolete = function(){
	document.body.innerHTML = "app cache obsolete. will update.";
	window.applicationCache.update();
};
