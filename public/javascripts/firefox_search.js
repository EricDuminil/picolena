function addEngine(name,ext,cat)
{
	if ((typeof window.sidebar == "object") && (typeof
	window.sidebar.addSearchEngine == "function"))
	{
		window.sidebar.addSearchEngine(
			"http://my_server.org/firefox_search/"+name+".src",
			"http://my_server.org/firefox_search/"+name+"."+ext,
			name,cat);
		alert('Download completed');
	}
	else
	{
		errorMsg(name,ext,cat);
	}
}