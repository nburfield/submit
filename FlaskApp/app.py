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
from celery import Celery 

static_directory = os.environ["SUBMIT_COMPILE_PATH"]
app = Flask(__name__)

#celery = Celery(app.name, backend='amqp://guest:guest@localhost:5672//', broker='amqp://guest:guest@localhost:5672//')
celery = Celery(app.name, backend='rpc://', broker='pyamqp://')
celery.conf.update(
    task_serializer='json',
    result_serializer='json')

def after_this_request(func):
	print ("function", func)	
	if not hasattr(g, 'after_request_callbacks'):
		g.after_request_callbacks = []
	g.after_request_callbacks.append(func)
	return func

@app.route("/submission", methods=['POST','PATCH'])
def submission():
	app.logger.debug("JSON received...")
	app.logger.debug(request.json)	

	# Generate Key and place that in return 
	m =  hashlib.sha256(request.json['details']['username'].encode('utf-8')).hexdigest()
	g.json_item = request.json
	g.key = m

	@after_this_request		
	def run_program(response):
		return m
	json = g.get('json_item')
	key = g.get('key')
	dataout = my_submissiontask.delay(json, key)
	return m

@app.route("/testcase", methods=['POST','PATCH'])
def test():
	app.logger.debug("JSON received...")
	app.logger.debug(request.json)
	# Generate Key and place that in return 
	m =  hashlib.sha256(request.json['details']['username'].encode('utf-8')).hexdigest()
	g.json_item = request.json
	g.key = m

	@after_this_request		
	def run_program(response):
		return m
	json = g.get('json_item')
	key = g.get('key')
	dataout = my_testcase.delay(json, key)
	headers = {'Content-Type' : 'application/json'}
	h = http.client.HTTPConnection('hpcvis3.cse.unr.edu:3000')
	h.request('POST', '/api_submission/create_output/' + str(json['details']["test_case_id"]), dataout.get(), headers )
	return m

#Submissiom	
@celery.task
def my_submissiontask(json, key):
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
	error = err.decode()
	
	if not error  or "warning" in error.lower():
		Compile = {"Status" : True, "Error" : None}
	# Run testcases
		for rm in json['RunMethods']:
			for input in rm:
				output = {}
				Output = {}
				filepath = directory + '/' + input['name']
				with open(filepath, 'w') as f:
					f.write(str(input['content']))
				
			 
				shell = run_script(static_directory, json['details']['username'], input['command'], filepath, json['details']["cputime"], json['details']['coresize'])
				mypath = directory + '/'+ "stderr.txt"
				with open(mypath, 'w') as err:
				 proc = subprocess.Popen(shell, shell = True, stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr=err)
				 proc.communicate()
					
				
				fileSize = os.stat(mypath)				
				if fileSize.st_size < 25000:
					errorFile = open(mypath, 'r')
					errorFileContents = errorFile.read() 
					errorFile.close()
				else:
					errorFileContents = "File too big to read"

				fileSize = os.stat(filepath + "_output")
				if fileSize.st_size < 25000:
					outputFile = open(filepath + "_output", 'r')
					outputFileContents = outputFile.read()
					outputFile.close()
				else:
					outputFileContents = "File too big to read"

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
			
		
					data1 = {"key" : key , "submission": submission, "Assignment_name" : json['details']['assignmentname'], "Assignment_id" : json['details']['assignment_id'] , "Student_ID" : json['details']['userid'], "Compile" : Compile, "Run" : output}
					print(data1)
					string = JSONEncoder().encode(data1)
					send(string, json['details']["sid"])
					f = open ("out.json", 'w')
					f.write(string)
					f.close()
								
	else :
		print ("error")
		Compile = {"Status" : False, "Error" : error}
		data1 = {"key" : key , "submission": submission, "Assignment_name" : json['details']['assignmentname'], "Assignment_id" : json['details']['assignment_id'], "Student_ID" : json['details']['username'],"Compile" : Compile}
		string = JSONEncoder().encode(data1)
		send(string, json['details']["sid"])
		f = open ("out.json", 'w')
		f.write(string)
		f.close()

	#rm -rf directory
	if os.path.exists(directory):
	 shutil.rmtree(directory)

	return string

#Creates Testcase
@celery.task
def my_testcase(json, key):
	directory = static_directory + "/" + json['details']['username']

	# mk directory
	if not os.path.exists(directory):
		os.mkdir(directory, mode=0o777)
	for x in json['sourcefiles']:
		if x != None :
			filepath = directory + '/' + x['name']
			with open(filepath, 'w') as f :
				os.chmod(filepath, mode=0o777)
				f.write(str(x['content']))
				f.close 

	for x in json['sharedfiles'].keys():
		filepath = directory + '/' + json['sharedfiles']['name']
		if json['sharedfiles'][x] != json['sharedfiles']['name'] :
			with open(filepath, 'w') as f:
				f.write(json['sharedfiles'][x])
				f.close

	testcase = {"id" : json['details']['test_case_id']}

	make = subprocess.Popen("make -C " + static_directory + "/" + json['details']['username'], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)   
	out, err = make.communicate()
	error = err.decode()
	if not error  or "warning" in error.lower():
	# Run testcases
		Compile = {"Status" : True, "Error" : None}
		output = {}		
		for rm in json['RunMethods']:
			Output = {}
			run_method = {}
			for input in rm:			
				filepath = directory + '/' + input['name']
				with open(filepath, 'w') as f:
					f.write(str(input['content']))
				run_method ={"id" : input['Id']}
				shell = run_script(static_directory, json['details']['username'], input['command'], filepath, json['details']["cputime"], json['details']['coresize'])
				mypath = directory + '/'+ "stderr.txt"
				with open(mypath, 'w') as err:
					proc = subprocess.Popen(shell, shell = True, stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr=err)
					proc.communicate()

					fileSize = os.stat(mypath)
					if fileSize.st_size < 25000:
						errorFile = open(mypath, 'r')
						errorFileContents = errorFile.read()
						errorFile.close()
					else:
						errorFileContents = "File too big to read"

					fileSize = os.stat(filepath + "_output")
					if fileSize.st_size < 25000:
						outputFile = open(filepath + "_output", 'r')
						outputFileContents = outputFile.read()
						outputFile.close()
					else:
						outputFileContents = "File too big to read"
					if errorFileContents:
						Output[input['input_id']]= {"Output" : outputFileContents, "Error" : errorFileContents }
					else:
						Output[input['input_id']]= {"Output" : outputFileContents, "Error" : None}

			output[input['Method']] = {"Result" : Output} 

		data1 = {"key" : key , "Username" : json['details']['username'], "User_id" : json['details']['userid'], "testcase" : testcase, "Compile" : Compile, "Run" : output, "RunMethod" : run_method }
		string = JSONEncoder().encode(data1)
		f = open ("out.json", 'w')
		f.write(string)
		f.close()

	else :
		print ("error")
		Compile = {"Status" : False, "Error" : error}
		data1 = {"key" : key ,"Username" : json['details']['username'], "User_id" : json['details']['userid'], "testcase" : testcase, "Compile" : Compile}
		string = JSONEncoder().encode(data1)
		f = open ("out.json", 'w')
		f.write(string)
		f.close()

	#rm -rf directory
	if os.path.exists(directory):
		shutil.rmtree(directory)
	 
	return string


@app.after_request
def call_after_requests(response):
	for callback in getattr(g, 'after_request_callbacks', ()):
		callback(response)
	return response

def send(string, ID):
	headers = {'Content-Type' : 'application/json'}
	h = http.client.HTTPConnection('hpcvis3.cse.unr.edu:3000')
	h.request('POST','/api_submission/run_program/' + str(ID) , string, headers)
	return

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
	app.run(host='0.0.0.0')	  	
