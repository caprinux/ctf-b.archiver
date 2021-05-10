#!/bin/bash

echo "Welcome to CTFSG b-archiver."
read -p "CTF.SG Website Handle (i.e. Cyberthon21f): " webhandle
read -p "Email: " username
read -p "Password: " password
echo ""
echo "Logging in..."
response=$(curl -XPOST "https://api.$webhandle.ctf.sg/graphql" \
	-H "Content-Type: application/json" \
	-d '{"operationName":"logIn","variables":{"email":"'"${username}"'","password":"'"${password}"'"},"query":"mutation logIn($email: String!, $password: String!) {authenticateUser(email: $email, password: $password)}"}' 2>/dev/null)  
if [[ $response =~ '{"data":{"authenticateUser":"' ]]
then
	echo "Logged in. Stealing your credentials now."
else
	echo "Login failed. Did you put the right credentials/website?"
	exit 1
fi
token=$(echo $response | sed -e 's/{"data":{"authenticateUser":"//g' | sed -e 's/"}}//g')

response2=$(curl "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw '{"operationName":null,"variables":{},"query":"{competitions {id}}"}' 2>/dev/null)

compid=$(echo $response2 | sed -e 's/{"data":{"competitions":\[{"id":"//g' | sed -e 's/"}]}}//g' | sed -e 's/"},{"id":"/ /g')
echo $compid
responsename=$(curl "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw '{"operationName":null,"variables":{},"query":"{\n  userSelf {\n    username\n }\n}\n"}' 2>/dev/null)

name=$(echo $responsename | sed -e 's/{"data":{"userSelf":{"username":"//g' | sed -e 's/"}}}//g' 2>/dev/null )

echo ""
echo "Now I know you are $name..."
echo "Watch your doors and windows at night..."
echo ""
echo "I'm actually TOTALLY TOTALLY not finding your location, just getting challenge ids."

id=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw '{"operationName":"competitionGameData","variables":{"id":"'$compid'"},"query":"query competitionGameData($id: ID!) {competition(id: $id) { challenges { id __typename } __typename}}"}'| sed -e 's/"id":"//g' | sed -e 's/",//g' | sed -e 's/{"data":{"competition":{"challenges":\[{//g' | sed -e 's/"__typename":"Challenge"},{/ /g' | sed -e 's/"__typename":"Challenge"}],"__typename":"Competition"}}}//g' 2>/dev/null) 

compname=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw '{"operationName":null,"variables":{},"query":"{competitions {name}}"}' | sed 's/{"data":{"competitions":\[{"name":"//g' | sed 's/"}]}}//g' | sed 's/"},{"name":"/ /g' 2>/dev/null )

echo "Ongoing Competition: $compname"
echo -n "Number of challenges to downloaded: "
echo -n $id | wc -w

FILE=$compname

if test -f "$FILE"
then
  echo "$FILE already exists. Exiting."
	exit 1
else
	echo "Creating folder '$FILE'"
	mkdir "$FILE"
fi

for d in $id
do
	#name 
	challname=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw $'{"operationName":"challenge","variables":{"id":"'$d'"},"query":"query challenge($id: ID\u0021) {challenge(id: $id) {name}}"}' | sed -e 's/{"data":{"challenge":{"name":"//g' | sed -e 's/"}}}//g' 2>/dev/null)

	#category
	challcat=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw $'{"operationName":"challenge","variables":{"id":"'$d'"},"query":"query challenge($id: ID\u0021) {challenge(id: $id) {category}}"}' | sed -e 's/{"data":{"challenge":{"category":"//g' | sed -e 's/"}}}//g' 2>/dev/null)

	mkdir ./"$compname"/"$challcat" 1>/dev/null 2>/dev/null
	mkdir ./"$compname"/"$challcat"/"$challname"
	
	#description
	challdesc=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw $'{"operationName":"challenge","variables":{"id":"'$d'"},"query":"query challenge($id: ID\u0021) {challenge(id: $id) {description}}"}' | sed -e 's/{"data":{"challenge":{"description":"Category: //g' 2>/dev/null )
	echo -ne $challdesc > ./"$compname"/"$challcat"/"$challname"/Description
	echo $challname
	
	#file
	challfile=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw $'{"operationName":"challenge","variables":{"id":"'$d'"},"query":"query challenge($id: ID\u0021) {challenge(id: $id)  {files{url}}}"}' | sed 's/{"data":{"challenge":{"files":\[{"url":"//g' | sed 's/"}]}}}//g' | sed 's/"}//g' | sed 's/{"url":"/ /g' | sed 's/,//g' | sed -e 's/\\u0026/\&/g' 2>/dev/null )
	challfilename=$(curl --silent "https://api.$webhandle.ctf.sg/graphql" -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw $'{"operationName":"challenge","variables":{"id":"'$d'"},"query":"query challenge($id: ID\u0021) {challenge(id: $id) {files{name}}}"}' | sed 's/{"data":{"challenge":{"files":\[{"name":"//g' | sed 's/"},{"name":"/ /g' | sed 's/"}]}}}//g' 2>/dev/null)
	

	for filez in $challfile
	do
		namaeee=$(echo $filez | awk -F= '{print $3}')
		wget -O ./"$compname"/"$challcat"/"$challname"/"$namaeee" $filez 1>/dev/null 2>/dev/null 
	done

done


