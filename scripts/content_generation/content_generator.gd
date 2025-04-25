extends Node
class_name ContentGenerator

signal content_received(data: Dictionary)
signal error_received(error_message: String)

var api_endpoint = "http://localhost:5000/generate"

var http_request: HTTPRequest

func _ready():
    if not http_request:
        print("LLM_Communicator: Creating HTTPRequest node.")
        http_request = HTTPRequest.new()
        add_child(http_request)

    http_request.request_completed.connect(_on_request_completed)

func request_content(prompt_instruction: String, context_info: String = ""):
    print("LLM_Communicator: Requesting content...")

    var headers = ["Content-Type: application/json"]

    var system_message = "You are a helpful game master assistant for the fantasy RPG Omennis. Respond ONLY with valid JSON matching the requested structure."
    var user_request = prompt_instruction
    if not context_info.is_empty():
        user_request += "\n\nGame Context : \n" + context_info

    var json_format_instruction = """
    Please respond ONLY with a single, valid JSON object matching this exact structure:
    {
	    "id" : "",
	    "name": "",
    	"description" :	"",
		"possibilities" : [
	    	{
		    	"id" : "leave", 
			    "description" : ""
		    },
		    {
			    "id" : "leave", 
			    "description" : ""
		    },
		    {
			    "id" : "leave", 
			    "description" : ""
		    }
	    ]
    }

    Here is an example of output : 

    {
    	"id": "campfire_shared_hope",
	    "name": "A Glimmer of Hope",
    	"description": "Around the crackling campfire, [Name 0] and [Name 1] share tales of the harsh road. Despite the grim talk, a quiet understanding forms. 'It's... less lonely, traveling with others,' [Name 1] admits softly.",
	    "possibilities": [
    		{
		    	"id": "leave",
	    		"description": "Offer [Name 1] the last piece of your dried fruit.",
    		},
		    {
	    		"id": "leave",
    			"description": "Share a genuinely hopeful story from before the hard times.",
			    "outcome_hint": "[Name 1] relationship +1 (Trust), [Name 1] morale boost."
		    },
	    	{
    			"id": "leave",
			    "description": "Nod quietly and retreat into your own thoughts.",
			    "outcome_hint": "No relationship change, missed opportunity for bonding."
		    }
	    ]
    }

     """

    var full_prompt = system_message + "\n\n" + user_request + "\n\n" + json_format_instruction

    var payload = {
        "prompt" : full_prompt,
        "temperature": 0.7
    }

    var body_string = JSON.stringify(payload)
    
    var error = http_request.request(api_endpoint, headers, HTTPClient.METHOD_POST, body_string)

    if error != OK:
        var error_message = "LLM_Communicator: HTTPRequest initiation failed with error code: " + str(error)
        printerr(error_message)
        emit_signal("error_received", error_received)

func _on_request_completed(result, response_code, _headers, body) :
    if result != HTTPRequest.RESULT_SUCCESS:
        var error_message = "LLM_Communicator: HTTPRequest failed. Result code: " + str(result)
		# Specific check for connection error
        if result == HTTPRequest.RESULT_CANT_CONNECT:
            error_message += " - Could not connect to the Python server at " + api_endpoint + ". Is hf_server.py running?"
        printerr(error_message)
        emit_signal("error_received", error_message)
        return

    if response_code < 200 or response_code >= 300 :
        var error_message = "LLM_Communicator: Received non-success HTTP status code: " + str(response_code)
        printerr(error_message)
		# Attempt to get error details from the body if available
        var server_error_details = body.get_string_from_utf8()
        printerr("Server Response Body: ", server_error_details)
        emit_signal("error_received", error_message + " | Server response: " + server_error_details)
        return

    var json_string_from_server = body.get_string_from_utf8()
    var server_response_parse = JSON.parse_string(json_string_from_server)

    if server_response_parse == null:
        var error_message = "LLM_Communicator: Failed to parse JSON response from Flask server."
        printerr(error_message)
        printerr("Raw server response: ", json_string_from_server)
        emit_signal("error_received", error_message)
        return

    if not server_response_parse is Dictionary:
        var error_message = "LLM_Communicator: Unexpected response format from Flask server (expected JSON Dictionary)."
        printerr(error_message)
        printerr("Parsed server response: ", server_response_parse)
        emit_signal("error_received", error_message)
        return

    if server_response_parse.has("error"):
        var server_error = server_response_parse["error"]
        var error_message = "LLM_Communicator: Python server reported an error: " + str(server_error)
        printerr(error_message)
        emit_signal("error_received", error_message)
        return

    if not server_response_parse.has("generated_text"):
        var error_message = "LLM_Communicator: Response from Flask server is missing 'generated_text' field."
        printerr(error_message)
        printerr("Parsed server response: ", server_response_parse)
        emit_signal("error_received", error_message)
        return

    var llm_generated_string = server_response_parse["generated_text"]
    var final_data_parse = JSON.parse_string(llm_generated_string)

    if final_data_parse == null:
        var error_message = "LLM_Communicator: Failed to parse the JSON content generated by the LLM. The LLM likely did not follow the format instruction."
        printerr(error_message)
        printerr("LLM's raw output string: ", llm_generated_string)
        emit_signal("error_received", error_message + " | LLM Raw Output: " + llm_generated_string)
        return

    if not final_data_parse is Dictionary:
        var error_message = "LLM_Communicator: Parsed LLM content is not a Dictionary as expected."
        printerr(error_message)
        printerr("Parsed LLM data: ", final_data_parse)
        emit_signal("error_received", error_message)
        return

    print("LLM_Communicator: Successfully received and parsed content.")
    print("Final Data: ", final_data_parse) # Optional: Print the successful data
    emit_signal("content_received", final_data_parse)
    