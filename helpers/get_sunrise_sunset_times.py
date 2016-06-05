#!/usr/bin/python
import json
import sys
import httplib

def Usage(args):
	print("Usage: " + args[0] + " latitude longitude")
	sys.exit()

def main(args):
	lat = args[0]
	lon = args[1]
	api_endpoint = "api.sunrise-sunset.org"
	conn = httplib.HTTPConnection(api_endpoint)
	conn.request("GET", "/json?lat=" + lat + "&lng=" + lon + "&data=today&formatted=0")
	response = conn.getresponse()
	if response.status != 200:
		raise AssertionError("Expected to get a 200 response!")
	jsonres = json.load(response)
	print jsonres['results']['sunrise']
	print jsonres['results']['sunset']

if __name__ == '__main__':
	args = sys.argv
	if (len(args) < 3):
		Usage(args)
	else:
		main(args[1:])