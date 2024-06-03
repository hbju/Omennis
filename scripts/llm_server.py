from flask import Flask, request, jsonify
import ollama
import logging
import sys
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.DEBUG)

def log_with_timestamp(message):
    logging.debug(f"{datetime.now()} - {message}")

def generate_event(prompt, model):
  system_message = "You are to provide me content for my dark fantasy game, Omennis, where the player has a party of a few characters that roam the world, taking up quests, defeating monsters, leveling up, earning fame and glory. \n {\"id\" : \"\",\"name\": \"\",\"description\" : \"\",\"possibilities\" : [{\"possibility_id\" : \"\",\"possibility_description\" : \"\"},{\"possibility_id\" : \"\",\"possibility_description\" : \"\"},{\"possibility_id\" : \"\",\"possibility_description\" : \"\"}]} \n When I ask you to write an event, write it under the above .json template. \"id\" is the id of the event, \"name\" is the name of the event that will be displayed to the player and \"description\" is the text of the event the player will read. Each possibility is a button taking the player to a new event, with \"possibility_id\" being the id of the event the player is taken to, and \"possibility_description\" is the text that will be displayed on the button. The text must be not too long, so the player doesn't lose interest (maximum two paragraphs). You can add as many possibilities as you want. All event ids must be in snake_case and as short as possible, so it is easy to reference them. The possibility descriptions should be short (max one sentence), so the possibilities buttons are not too big."

  # Generate response using Ollama and the given model
  response = ollama.chat(model = model, messages = [
    {"role": "system", "content": system_message},
    {"role": "user", "content": prompt}
  ])

  # return the generated response
  return response["message"]["content"]

@app.route('/generate', methods=['POST'])
def generate() : 
  start_time = datetime.now()
  data = request.json
  log_with_timestamp(f"Received data: {data}")
  prompt = data.get('prompt', 'Generate a random event')
  model = data.get('model', 'phi3')
  generated_content = generate_event(prompt, model)
  log_with_timestamp(f"Generated content: {generated_content}")
  end_time = datetime.now()
  log_with_timestamp(f"Request handling time: {end_time - start_time}")
  return jsonify({"content": generated_content})

if __name__ == '__main__':
  app.run(port='5000')