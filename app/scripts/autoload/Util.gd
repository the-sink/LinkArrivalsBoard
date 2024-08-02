extends Node

func make_request(http: HTTPRequest, url: String, headers: PackedStringArray = [], method: int = 0, request_data: String = ""):
	var err = http.request(url, headers, method, request_data)
	if err != OK:
		GlobalState.display_state = GlobalState.DisplayState.HTTP_ERROR
		return
	var response = await http.request_completed
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		GlobalState.display_state = GlobalState.DisplayState.HTTP_ERROR
		return
	return {
		"result": response[0],
		"response_code": response[1],
		"headers": response[2],
		"body": response[3]
	}
