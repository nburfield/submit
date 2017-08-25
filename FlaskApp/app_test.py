from flask import Flask, request, g
import json
import os
import shutil
import subprocess
from json import JSONEncoder
from flask import Response
import http
import hashlib

static_directory = os.environ["SUBMIT_COMPILE_PATH"]

app = Flask(__name__)

@app.route("/test", methods=['POST','PATCH'])
def test():
	app.logger.debug("JSON received...")
	app.logger.debug(request.json)

	print(request.json)
	print (request.json['details']['username'])
	directory = static_directory + "/" + request.json['details']['username']
	if not os.path.exists(directory):
		os.mkdir(directory, mode=0o777)

	for x in request.json['sourcefiles']:
		if x != None :
			filepath = directory + '/' + x['name']
			with open(filepath, 'w') as f :
				os.chmod(filepath, mode=0o777)
				f.write(str(x['content']))
				f.close 

	for x in request.json['sharedfiles'].keys():
		filepath = directory + '/' + request.json['sharedfiles']['name']
		if request.json['sharedfiles'][x] != request.json['sharedfiles']['name'] :
			with open(filepath, 'w') as f:
				f.write(request.json['sharedfiles'][x])
				f.close

	make = subprocess.Popen("make -C " + static_directory + "/" + request.json['details']['username'], shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)   
	out, err = make.communicate()
	error = err.decode()
	if not error  or "warning" in error.lower():
	# Run testcases
		for rm in request.json['RunMethods']:
			Output = {}
			for input in rm:
				filepath = directory + '/' + input['name']
				with open(filepath, 'w') as f:
					f.write(str(input['content']))

				shell = run_script(static_directory, request.json['details']['username'], input['command'], filepath, request.json['details']["cputime"], request.json['details']['coresize'])
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
						Output[input['input_id']]= {"Output" : outputFileContents, "Error" : None }

		data1 = {"Username" : request.json['details']['username'], "User_id" : request.json['details']['userid'], "Result" : Output }
		string = JSONEncoder().encode(data1)
		f = open ("out.json", 'w')
		f.write(string)
		f.close()

	else :
		print ("error")
		Compile = {"Status" : False, "Error" : error}
		data1 = {"Username" : request.json['details']['username'], "User_id" : request.json['details']['userid'],"Compile" : Compile}
		string = JSONEncoder().encode(data1)
		f = open ("out.json", 'w')
		f.write(string)
		f.close()
	#rm -rf directory
	if os.path.exists(directory):
		shutil.rmtree(directory)

	
	 
	return "done"

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