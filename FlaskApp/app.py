from flask import Flask, request, g
import json
import os
import shutil
import subprocess
import difflib
from json import JSONEncoder
from flask import Response
import http
import hashlib

static_directory = os.environ["SUBMIT_COMPILE_PATH"]

app = Flask(__name__)


@app.route("/json", methods=['POST','PATCH'])
def json():
  app.logger.debug("JSON received...")
  app.logger.debug(request.json)

  print(request.json)
  print(request.json['details']['username'])
  

  # Generate Key and place that in return
 
  m =  hashlib.sha256(request.json['details']['username'].encode('utf-8')).hexdigest()
  
 
  g.json_item = request.json
  g.key = m


  return m


@app.after_request
def run_program(response):
  json = g.get('json_item')
  key = g.get('key')

  directory = static_directory + "/" + json['details']['username']

  # mk directory
  if not os.path.exists(directory):
    os.mkdir(directory, mode=0o777)

  for x in json['studentfiles']:
    if x != None :
      filepath = directory + '/' + x['name']
      with open(filepath, 'w') as f :
        os.chmod(filepath, mode=0o777)
        f.write(str(x['content']))
        f.close
    
  for x in json['sharedfiles'].keys():
    filepath = directory + '/' + json['sharedfiles']['name']
    if  json['sharedfiles'][x] != json['sharedfiles']['name'] :
      with open(filepath, 'w') as f:
        f.write(json['sharedfiles'][x])
        f.close
 
  # Make the submission string
  submission = {"id" : json['details']["sid"]}

  # Compiles file
  make = subprocess.Popen("make -C " + static_directory + "/" + json['details']['username'], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)   
  out, err = make.communicate()

  if not err or "warning" in err.lower():
    Compile = {"Status" : True, "Error" : None}
  # Run testcases
    output = {}
    for rm in json['RunMethods']:
      Output = {}
      for input in rm:
        filepath = directory + '/' + input['name']
        with open(filepath, 'w') as f:
          f.write(str(input['content']))
        
       
        shell = run_script(static_directory, json['details']['username'], input['command'], filepath, json['details']["cputime"], json['details']['coresize'])
        mypath = directory + '/'+ "stderr.txt"
        with open(mypath, 'w') as err:
         proc = subprocess.Popen(shell, shell = True, stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr=err)
         proc.communicate()
        

        errorFile = open(mypath, 'r')
        outputFile = open(filepath + "_output", 'r')
        errorFileContents = errorFile.read()
        outputFileContents = outputFile.read()
        errorFile.close()
        outputFile.close()
        if errorFileContents:
          Output[input['input_id']]= {"Output" : outputFileContents, "Difference" : None, "Error" : errorFileContents }
        else:
          diff = list(difflib.ndiff(outputFileContents.splitlines(1), input['output'].splitlines(1)))
          for x in diff:
            if x.startswith('-'):
              difference = "".join(diff)
            else:
              if x.startswith(" "):
                difference = None
         
          Output[input['input_id']]= {"Output" : outputFileContents, "Difference" : difference, "Error" : None }
      output[input['Method']] = {"Result" : Output} 
      
    
    data1 = {"key" : key , "submission": submission, "Assignment_name" : json['details']['assignmentname'], "Assignment_id" : json['details']['id'] , "Student_ID" : json['details']['userid'], "Compile" : Compile, "Run" : output}
    string = JSONEncoder().encode(data1)
    f = open ("out.json", 'w')
    f.write(string)
    f.close()
    
  else :
    Compile = {"Status" : False, "Error" : err}
    data1 = {"key" : key , "submission": submission, "Assignment_name" : json['details']['assignmentname'], "Assignment_id" : json['details']['id'], "Student_ID" : json['details']['username'],"Compile" : Compile}
    string = JSONEncoder().encode(data1)
    f = open ("out.json", 'w')
    f.write(string)
    f.close()

  #rm -rf directory
  if os.path.exists(directory):
   shutil.rmtree(directory)

  headers ={'Content-Type' : 'application/json'}
  h = http.client.HTTPConnection('localhost:3000')
  h.request('POST','/api_submission/run_program/' + str(json['details']["sid"]) , string, headers )

  return response

#Creats a script to run 
def run_script(directory, dir_name, run_command, file, cpu_time, core_size):
  run = directory + '/' + dir_name + '/' + run_command + " < " + file + " > " +  file + "_output" + "\n"
  shell = "#!/bin/bash\n"
  shell = shell + "ulimit -t " + str(cpu_time)
  shell = shell + "\n" 
  shell = shell + "ulimit -c " + str(core_size)
  shell = shell + "\n"
  shell = shell + run
  shell = shell + "exit\n"
  return shell 

    
if __name__ == "__main__":
  app.run()
