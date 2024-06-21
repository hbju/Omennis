extends Node
class_name ContentGenerator

var http_request: HTTPRequest
const SYSTEM_MESSAGE: String = ("You are to provide me content for my dark fantasy game, Omennis, where the player has a party of a few characters that roam the world, taking up quests, defeating monsters, leveling up, earning fame and glory. \n" +
    "{\n" +
    "\"id\" : \"\", \n" + 
    "\"name\": \"\", \n" + 
    "\"description\" : \"\", \n" + 
    "\"possibilities\" : \n" + 
    "[{\"possibility_id\" : \"\", \n" + 
    "\"possibility_description\" : \"\"}, \n" + 
    "{\"possibility_id\" : \"\", \n" + 
    "\"possibility_description\" : \"\"}, \n" + 
    "{\"possibility_id\" : \"\", \n" + 
    "\"possibility_description\" : \"\"}]} \n" + 
    "When I ask you to write an event, write it using the above .json template. \"id\" is the id of the event, \"name\" is the name of the event that will be displayed to the player and \"description\" is the text of the event the player will read. Each possibility represents a button that the player can choose to go to a new event, with \"possibility_id\" being the id of the event the player is taken to, and \"possibility_description\" is the text that will be displayed on the button.\n" +
    "The event description must be not too long, so the player doesn't lose interest (maximum two paragraphs). You can add as many possibilities as you want. All event ids must be in snake_case and as short as possible, so it is easy to reference them. The possibility descriptions should be short (max one sentence), so the possibilities buttons are not too big.")


func _ready	() : 
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

func generate_event(prompt: String):
    var url = "http://127.0.0.1:11434/api/chat"
    var data = {
        "messages": [{"role" : "system", "content" : SYSTEM_MESSAGE}, {"role" : "user", "content" : prompt}],
        "model": "phi3",  # Use the model you specified
        "stream": false
  }
    var headers = ["Content-Type: application/json"]
    var json_data = JSON.stringify(data)
    http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)

func _on_request_completed(_result, response_code, _headers, body):
    print("Response code: ", response_code)
    print("Response body: ", body.get_string_from_utf8())
    if response_code == 200:
        var json = JSON.new()
        var error = json.parse(body.get_string_from_utf8())
        if error == OK : 
            var generated_text = json.data.message.content
            print("Generated Text: " + generated_text)
        # Handle the generated event text as needed
    else:
        print("Request failed, status code: ", response_code)
