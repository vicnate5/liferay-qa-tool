#!/bin/bash

# Welcome to the Liferay QA Tool
# This script can be used to accomplish many repetative bundle tasks that we do in QA.
# In order to use it, you simply need to set the variables below for your enviroment.

######################################################################################################################
#ENVIROMENT VARIABLES#################################################################################################
######################################################################################################################

## User Information ##
name="Victor"
# username is the value used to name your test.${username/computername}.properties
username="vicnate5"

## Operating System ##
# set to "windows", "osx", or "linux"
OS="osx"

## MySQL login ##
# this can usually be left blank
mysqlUsername=
mysqlPassword=

## POSHI Suite Function ##
# There is a function in this tool that runs all tests that are listed in the specified file:
# suite1.txt
# or
# suite2.txt 
#
# If you would like to use this function
# these files needs to be in your base source directory of the branch you want to use.
#
# You can list out as many tests as you like in one of these files, one test per line.
# Example:
#
# -suite1.txt-
# PortalSmoke#Smoke
# WebContent#AddWebContent
#
# These files also must contains a single blank line at the end of the file 
# to ensure all the tests are read.

## MySQL Databases ##
masterDB="master"
ee62xDB="ee62"
ee70xDB="ee7"
ee61xDB="ee61"
ee6210DB="ee621"
eeMasterDB="eeMaster"
ce62xDB="ce62"
ce70xDB="ce7"

## Bundle ports ##
# e.g. for 9080 put 9
masterPort="9"
ee62xPort="7"
ee70xPort="8"
ee61xPort="6"
ee6210Port="8"
eeMasterPort="6"
ce62xPort="8"
ce70xPort="5"

## Test Results Location ##
# where you want your test reports to end up
resultsDir="/Users/vicnate5/RESULTS"

## Portal Directories ##
sourceDir="/Users/vicnate5/Liferay"
bundleDir="/Users/vicnate5/bundles"

masterSourceDir="$sourceDir/liferay-portal-master"
masterBundleDir="$bundleDir/master-bundles"
masterPluginsDir="$sourceDir/liferay-plugins-master"

ee62xSourceDir="$sourceDir/liferay-portal-ee-6.2.x"
ee62xBundleDir="$bundleDir/ee-6.2.x-bundles"
ee62xPluginsDir="$sourceDir/liferay-plugins-ee-6.2.x"

ee70xSourceDir="$sourceDir/liferay-portal-ee-7.0.x"
ee70xBundleDir="$bundleDir/ee-7.0.x"
ee70xPluginsDir="$sourceDir/liferay-plugins-ee-7.0.x"

ee61xSourceDir="$sourceDir/liferay-portal-ee-6.1.x"
ee61xBundleDir="$bundleDir/ee-6.1.x-bundles"
ee61xPluginsDir="$sourceDir/liferay-plugins-ee-6.1.x"

ee6210SourceDir="$sourceDir/liferay-portal-ee-6.2.10"
ee6210BundleDir="$bundleDir/ee-6.2.10-bundles"
ee6210PluginsDir="$sourceDir/liferay-plugins-ee-6.2.10"

eeMasterSourceDir="$sourceDir/liferay-portal-ee-master"
eeMasterBundleDir="$bundleDir/master-ee-bundles"

ce62xSourceDir="$sourceDir/liferay-portal-6.2.x"
ce62xBundleDir="$bundleDir/6.2.x-bundles"
ce62xPluginsDir="$sourceDir/liferay-plugins-6.2.x"

ce70xSourceDir="$sourceDir/liferay-portal-7.0.x"
ce70xBundleDir="$bundleDir/7.0.x"
ce70xPluginsDir="$sourceDir/liferay-plugins-7.0.x"

## Plugins ##
# This allows you to deploy a group of plugins that you use regularly
# There is one array variable for CE plugins and one for EE only plugins.
# You can list as many as you want.
# The CE plugins will be deployed on your EE bundles as well but not vis versa.

# ***These must be listed with their parent directory***
# e.g. webs/kaleo-web

cePlugins[0]="portlets/web-form-portlet"

eePlugins[0]="webs/kaleo-web"
eePlugins[1]="portlets/kaleo-forms-portlet"
eePlugins[2]="portlets/kaleo-designer-portlet"
eePlugins[3]="portlets/reports-portlet"
eePlugins[4]="webs/jasperreports-web"
eePlugins[5]="portlets/calendar-portlet"

## Bundle build sound ##
soundDir="/Users/vicnate5/Dropbox/Work/Scripts"
soundFile="bundleFinished.mp3"

## test.properties Location ##
testPropsDir="/Users/vicnate5/Dropbox/Work/files"

## Git Tools PRs
gitpr="/Users/vicnate5/Liferay/git-tools/git-pull-request/git-pull-request.sh"

######################################################################################################################
#FUNCTIONS############################################################################################################
######################################################################################################################

if [[ ${OS} == "osx" ]]
then
	open=open
	sed=gsed
elif [[ ${OS} == "linux" ]]
then
	open=xdg-open
	sed=sed
elif [[ ${OS} == "windows" ]]
then
	open=start
	sed=sed
fi


dbClear(){
	if [[ -n "$mysqlUsername" ]]; then
		if [[ -n "$mysqlPassword" ]]
		then
			mysql -u $mysqlUsername -p $mysqlPassword -e "drop database if exists $db; create database $db char set utf8;"
		else
			mysql -u $mysqlUsername -e "drop database if exists $db; create database $db char set utf8;"
		fi
	else
		mysql -e "drop database if exists $db; create database $db char set utf8;"
	fi
}

updateToHeadOption(){
	read -p "Update to HEAD? (y/n)?" -n 1 -r
		echo
		if [[ $REPLY = y ]]
		then
			echo "Yes"
			echo "Pulling Upstream"
			echo
			git pull upstream $v
			echo
			echo "Pushing to Origin"
			echo
			git push origin $v
		elif [[ $REPLY = n ]]
		then
			echo "No"
		else 
			echo "please choose Y or N"
			sleep 1
			continue
		fi
}

setupDatabaseConnection(){
	echo "Adding properties files"
	cp $testPropsDir/test.$username.properties $dir/
	echo app.server.parent.dir=$bundleDir >app.server.$username.properties

	if [[ $wf = "true" ]]
	then
		(echo "" ; echo "app.server.type=wildfly") >>app.server.$username.properties
	fi

	echo "Configuring test.$username.properties for MySQL"
	cd $dir
	if [[ -e test.$username.properties ]] 
	# if test.username.properties exists(-e)
	then
		if grep -q database.mysql.schema test.$username.properties 
		# if there is a test.username.properties file that already defines the database name
		then
			${sed} -i "s/database.mysql.schema=.*/database.mysql.schema=${db}/" test.$username.properties
			# basic inline(-i) search and replace
			# using ".*" regex to denote that it can contain any string in the rest of that line
		else
			(echo "" ; echo "database.mysql.schema=${db}") >>test.$username.properties
			# append the file with the database property after adding an extra line. 
			# this is to prevent the property being added to the end of a already populated line
		fi
	else
		echo "database.mysql.schema=${db}" >test.$username.properties
		# create file test.username.properties and add the database.name property
	fi

	if grep -q database.mysql.username test.$username.properties 
	then
		${sed} -i "s/database.mysql.username=.*/database.mysql.username=${mysqlUsername}/" test.$username.properties
	else
		(echo "" ; echo "database.mysql.username=${mysqlUsername}") >>test.$username.properties
	fi

	if grep -q database.mysql.password test.$username.properties 
	then
		${sed} -i "s/database.mysql.password=.*/database.mysql.password=${mysqlPassword}/" test.$username.properties
	else
		(echo "" ; echo "database.mysql.password=${mysqlPassword}") >>test.$username.properties
	fi

	echo "Adding portal URL"
	(echo "" ; echo "test.url=http://localhost:${port}080") >>test.$username.properties
	echo "Creating portal-ext.properties"
	ant -f build-test.xml prepare-portal-ext-properties
}

bundleBuild(){
	cd $dir

	read -p "Switch to main branch and update to HEAD? (y/n)?" -n 1 -r
		echo
		if [[ $REPLY = y ]]
		then
			echo "Checking for modified files"
			echo
			modified=$(git ls-files -m)
			if [ -n "$modified" ]
			then
				printf "\e[31mModified Files:\e[0m"
				echo $modified
				echo
				printf "\e[31mAny modified files will be cleared, are you sure you want to continue?\e[0m"
				printf "\e[31m[y/n?]\e[0m"

				read -n 1 -r
					echo
					if [[ $REPLY = y ]]
					then
						echo "Sweetness"
					elif [[ $REPLY = n ]]
					then
						echo "No"
						echo "Come back when you have committed or stashed your modified files."
						sleep 3
						continue
					else 
						echo "please choose y or n"
						sleep 1
						continue
					fi
			else
				echo "No modified files"
			fi

			echo "Switching to branch $v"
			git checkout $v
			echo	
			echo "Clearing Gradle Cache"
			rm -r $dir/.gradle/caches
			echo "Resetting main branch"
			git reset --hard
			echo
			echo "Pulling Upstream"
			echo
			git pull upstream $v
			echo
			echo "Pushing to Origin"
			echo
			git push origin $v
		elif [[ $REPLY = n ]]
		then
			echo "No"
		else 
			echo "please choose y or n"
			sleep 1
			continue
	fi

	if [[ $v != *ee-6.1* ]]
	then
		echo "Setting up portal-ext.properties"
		setupDatabaseConnection
	fi

	if [[ $wf = "true" ]]
	then
		echo
		echo "Building $v on WILDFLY"
		echo
		(echo "" ; echo "app.server.type=wildfly") >>app.server.$username.properties
		ant -f build-dist.xml unzip-wildfly
	else
		echo
		echo "Building $v on TOMCAT"
		echo
		ant -f build-dist.xml unzip-tomcat
	fi

	ant all
	
	if [[ $v == *ee-6.1* ]]
	then
		cd $bundleDir/tomcat-7.0.40/conf
	elif [[ $v == *6.2* ]]
	then
		cd $bundleDir/tomcat-7.0.62/conf
	else
		cd $bundleDir/tomcat-8.0.30/conf
	fi

	echo "Writing ports to ${port}080"
	${sed} -i "s/8005/${port}005/; s/8080/${port}080/; s/8009/${port}009/; s/8443/${port}443/g" server.xml
	echo "Remaking MySQL Database"
	dbClear
	echo "$db has been remade"

	# if [[ $v != *ee-6.1* ]]
	
	# then
	# 	echo "Adding virtual hosts property"
	# 	cd $bundleDir/tomcat-7.0.62/webapps/ROOT/WEB-INF/classes/
	# 	ip=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

	# 	if ! grep -q "virtual.hosts.valid.hosts" ./portal-ext.properties 
	# 	then
	# 		(echo "" ; echo "virtual.hosts.valid.hosts=localhost,127.0.0.1,$ip") >> portal-ext.properties
	# 	fi
	# fi

	echo "done"
	cd $soundDir
	afplay $soundFile &> /dev/null
	read -rsp $'Press any key to continue...\n' -n1 key
}

pluginsDeploy(){
	cd $pluginsDir
	echo "Plugins Branch Selected: $v"
	echo
	echo "--Plugins Selected--"
	echo "CE: ${cePlugins[*]}" | tr " " "\n" | ${sed} 's/.*\///'
	echo
	echo "EE: ${eePlugins[*]}" | tr " " "\n" | ${sed} 's/.*\///'
	echo
	updateToHeadOption

	for p in "${cePlugins[@]}"
	do
		echo "Deploying $p"
		cd $p && ant clean deploy
		echo "done"
		echo
		cd $pluginsDir 
	done

	if [[ $v == *ee* ]]
	then
		for p in "${eePlugins[@]}"
		do
			echo "Deploying $p"
			cd $p && ant clean deploy
			echo "done"
			echo
			cd $pluginsDir  
		done
	fi

	echo "done"
	read -rsp $'Press any key to continue...\n' -n1 key
}

clearEnv(){
	echo "Portal Version Selected: $v"
	echo
	read -p "Do you want to remove all plugins except marketplace? (y/n)?" -n 1 -r
		if [[ $REPLY = y ]]
		then
			echo
			echo "Clearing Plugins"

			if [[ $v == *ee-6.1* ]]
			then
				cd $bundleDir/tomcat-7.0.40/webapps && ls | grep -v "^ROOT\|^marketplace-portlet"  | xargs rm -r
			elif [[ $v == *6.2* ]]
			then
				cd $bundleDir/tomcat-7.0.62/webapps && ls | grep -v "^ROOT\|^marketplace-portlet"  | xargs rm -r
			else
				cd $bundleDir/tomcat-8.0.30/webapps && ls | grep -v "^ROOT\|^marketplace-portlet"  | xargs rm -r
			fi
			
			echo "done"
		elif [[ $REPLY = n ]]
		then
			echo "No"
			echo "Plugins untouched"
		else 
			echo "please choose y or n"
			sleep 1
			continue
		fi

	echo "Clearing Data and Logs"
	cd $bundleDir
	rm -r data logs
	echo "Remaking MySQL Database"
	dbClear
	echo "$db has been remade"
	echo "done"
	read -rsp $'Press any key to continue...\n' -n1 key
}

poshiFormat(){
	echo "Formatting POSHI files for $v"
	sleep 2
	cd $dir/portal-impl
	ant format-source
	echo
	echo "done"
}

poshiBuildSeleniumOption(){
	read -p "Do you need to Build Selenium First? (y/n)?" -n 1 -r
	echo
	if [[ $REPLY = y ]]
	then
		cd $dir/portal-impl
		echo "Building Selenium"
		ant build-selenium
		cd $dir
	elif [[ $REPLY = n ]]
	then
		echo "No"
	else 
		echo "please choose Y or N"
		sleep 1
		continue
	fi
}

poshiRunTest(){
	echo "Running $testname"
	sleep 2
	echo
	echo "Clearing Old Screenshots"
	cd $dir/portal-web/test-results/functional/screenshots && rm *.jpg
	cd $dir

	echo "Disabling Poshi Runner"
	${sed} -i "s~test.poshi.runner.enabled=.*~test.poshi.runner.enabled=false~" test.$username.properties

	if [ "$mobile" = "true" ]
	then
		${sed} -i "s/address}:8080/address}:${port}080/" build-test.xml
		${sed} -i 's/sleep seconds="120"/sleep seconds="30"/' build-test.xml
		ant -f run.xml run -Dtest.class=$testname -Dmobile.device.enabled=true < /dev/null
	else
		ant -f run.xml run -Dtest.class=$testname < /dev/null
	fi
	
	echo
	echo "Finished $testname"
	echo
	echo "Renaming report.html"
	time="$(date +"%H.%M")"
	mv $dir/portal-web/test-results/functional/report.html $dir/portal-web/test-results/functional/${v}_$testname.${time}.html
	echo "done"
	echo
	echo "Zipping Screenshots"
	echo
	cd $dir/portal-web/test-results/functional/screenshots
	zip Pictures$testname.zip *.jpg
	rm *.jpg
	echo "done"
}

poshiSuite(){
	T="$(date +%s)"

	echo "Choose a Test Suite to Run and hit [Enter]:"
	echo
	OPTIONS="Suite-1 Suite-2"
	select opt in $OPTIONS; do
		if [ "$opt" = "Suite-1" ]; then
			suiteNumber=1
			echo "$opt Selected"
			sleep 2
			break
		elif [ "$opt" = "Suite-2" ]; then
			suiteNumber=2
			echo "$opt Selected"
			sleep 2
			break
		else
			echo "Invalid option"
		fi
	done

	vim $dir/suite$suiteNumber.txt
	poshiBuildSeleniumOption	
	cd $dir

	while read testname;
	do
		poshiRunTest
		cd $dir
		continue
	done<suite$suiteNumber.txt

	echo
	printf "\e[31mALL TESTS COMPLETE\e[0m"
	echo
	echo "Zipping up results for you"
	sleep 2

	date="$(date +"%m-%d-%y")"
	time="$(date +"%H:%M")"

	info=Suite${suiteNumber}_${date}_${time}
	cd $dir/portal-web/test-results/functional/screenshots
	echo "Zipping screenshots"
	zip Results-Pictures-$info *.zip
	mv Results-Pictures-$info.zip $dir
	rm *.zip
	cd $dir
	mv Results-Pictures-$info.zip $resultsDir/Results-$info-PICTURES
	echo "done"

	echo
	echo "Zipping reports"
	cd $dir/portal-web/test-results/functional

	mkdir failed
	grep -l -Z -r 'div class="fail"' . | xargs -0 -i{} mv {} ./failed

	cd $dir/portal-web/test-results/functional
	zip Results-$info-PASSED *.html
	mv Results-$info-PASSED.zip $dir
	rm *.html

	cd failed
	zip Results-$info-FAILED *.html
	mv Results-$info-FAILED.zip $dir
	cd $dir/portal-web/test-results/functional
	rm -r failed

	echo "Sending your results to $resultsDir"
	cd $dir
	unzip Results-$info-PASSED.zip -d $resultsDir/Results-$info-PASSED
	unzip Results-$info-FAILED.zip -d $resultsDir/Results-$info-FAILED
	echo "done"

	## TO RUN ON ANOTHER ENVIROMENT

	# sleep 2
	
	# Needs to be replaced with VIX API cuz this doesn't actually shutdown the VM
	# killall -9 vmplayer	

	# vmplayer /home/vicnate5/VMs/posgresql/vm-winxp.vmx &> /dev/null &
	# sleep 60

	# vmplayer /home/vicnate5/VMs/CentOS\ 5/vm-centos5.vmx &> /vdev/null &
	# sleep 20

	# STILL DOESNT WORK
	# url="172.16.19.254:8080"
	# ${sed} -i "s/test.url=.*/test.url=$url/" /home/vicnate5/liferay/liferay-portal-ee-6.2.x/test.vicnate5.properties

	# cd $dir

	# while read testname;
	# do
	# 	poshiRunTest
	# 	cd $dir
	# 	continue
	# done<suite$suiteNumber.txt

	# echo
	# printf "\e[31mALL TESTS COMPLETE\e[0m"
	# echo
	# echo "Zipping up results for you"
	# sleep 2

	# date="$(date +"%m-%d-%y")"
	# time="$(date +"%H:%M")"

	# info=Suite${suiteNumber}_${date}_${time}
	# cd $dir/portal-web/test-results/functional/screenshots
	# echo "Zipping screenshots"
	# zip Results-Pictures-$info *.zip
	# mv Results-Pictures-$info.zip $dir
	# rm *.zip
	# cd $dir
	# mv Results-Pictures-$info.zip $resultsDir/Results-$info-PICTURES
	# echo "done"

	# echo
	# echo "Zipping reports"
	# cd $dir/portal-web/test-results/functional

	# mkdir failed
	# grep -l -Z -r 'div class="fail"' . | xargs -0 -I{} mv {} ./failed

	# cd $dir/portal-web/test-results/functional
	# zip Results-$info-PASSED *.html
	# mv Results-$info-PASSED.zip $dir
	# rm *.html

	# cd failed
	# zip Results-$info-FAILED *.html
	# mv Results-$info-FAILED.zip $dir
	# cd $dir/portal-web/test-results/functional
	# rm -r failed

	# echo "Sending your results to $resultsDir"
	# cd $dir
	# unzip Results-$info-PASSED.zip -d $resultsDir/Results-$info-PASSED
	# unzip Results-$info-FAILED.zip -d $resultsDir/Results-$info-FAILED
	# echo "done"

	echo
	T="$(($(date +%s)-T))"
	echo "Time in seconds: ${T}"
	echo
	printf "Pretty format: %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))"
	echo "done"
	echo
	printf "\e[31mResults can be found in $dir\e[0m"
	printf "\e[31mor in $resultsDir\e[0m"
	read -rsp $'Press any key to continue...\n' -n1 key
}

poshiRun(){
	echo "Running POSHI test for $v"
	poshiBuildSeleniumOption
	poshiRunTest
	echo "Copying your results to $resultsDir"
	cp $dir/portal-web/test-results/functional/${v}_$testname.${time}.html $resultsDir/
	read -rsp $'Press any key to continue...\n' -n1 key
}

poshiRunnerRun(){
	echo "POSHI Runner test for $v"
	cd $dir
	echo
	echo "Enabling Poshi Runner"
	echo
	${sed} -i "s~test.poshi.runner.enabled=.*~test.poshi.runner.enabled=true~" test.$username.properties
	ant -f build-test.xml run-selenium-test -Dtest.class=$testname < /dev/null
	echo
	echo "Finished $testname"
	echo
	prTestName=$(echo $testname | ${sed} 's/#/_/')
	${open} $dir/portal-web/test-results/$prTestName/index.html
	echo "done"
	read -rsp $'Press any key to continue...\n' -n1 key
}

poshiValidate(){
	cd $dir
	ant -f build-test.xml run-poshi-validation
	echo "done"
	read -rsp $'Press any key to continue...\n' -n1 key
}

poshiSetUrl(){
	echo -n "Enter Portal URL and press [ENTER]: "
	read url
	cd $dir

	if grep -q "test.url=" test.$username.properties 
	then
		${sed} -i "s~test.url=.*~test.url=${url}~" test.$username.properties
	else
		(echo "" ; echo "test.url=${url}") >>test.$username.properties
	fi
}

poshiSetTest(){
	echo -n "Enter full test name and press [ENTER]: "
	read testname
	echo "$testname"
}

gitInfoTemplate(){
	cd $dir
	portalID="$(git log --pretty=format:'%H' -n 1)"
	cd $pluginsDir
	pluginsID="$(git log --pretty=format:'%H' -n 1)"
	echo
	echo "$v:"
	echo "Tomcat 7.0.62 + MySQL 5.6 Portal $v GIT ID: $portalID."
	echo "Plugins $v GIT ID: $pluginsID."
	echo
	read -rsp $'Press any key to continue...\n' -n1 key
}

updateFixPriorities(){
	echo
	echo -n "Enter New Priority and press [ENTER]: "
	read priority
	vim $resultsDir/fp.txt
	echo
	cd $dir

	local IFS=#
	while read testcase testcommand;
	do
		testcasefile=$(find . -name "$testcase.testcase")
		${sed} -i "s/name=\"${testcommand}\" priority=\".*\"/name=\"${testcommand}\" priority=\"${priority}\"/" $testcasefile
		cd $dir
		continue
	done<$resultsDir/fp.txt
	echo "done"
	echo "$priority's added"
	read -rsp $'Press any key to continue...\n' -n1 key
}

addKnownIssues(){
	echo
	echo
	vim $resultsDir/addki.txt
	echo
	echo
	echo -n "Enter Ticket to Add and press [ENTER]: "
	read ticket
	cd $dir

	local IFS=#
	while read testcase testcommand;
	do
		testcasefile=$(find . -name "$testcase.testcase")
		${sed} -i "s/name=\"${testcommand}\"/known-issues=\"${ticket}\"\ name=\"${testcommand}\"/" $testcasefile
		cd $dir
		continue
	done<$resultsDir/addki.txt
	echo "done"
	echo "known-issues $ticket added"
	read -rsp $'Press any key to continue...\n' -n1 key
}

getQATicketNumber(){
	cd $dir
	local IFS="-" 
	read -a elements <<< "$(git rev-parse --abbrev-ref HEAD)"

	if [[ $v != *ee-* ]]
	then
		ticket=${elements[2]}
	else
		ticket=${elements[3]}
	fi

	echo "$ticket"
}

qaPullRequest(){
	local ticket=$(getQATicketNumber)
	git log -n 4
	echo
	printf "\e[31mTicket: LRQA-${ticket}\e[0m"
	echo "Submit a Pull Request?"
	echo "[y/n?]"
	read -n 1 -r
		if [[ $REPLY = y ]]
		then
			$gitpr submit --update-branch=${v} "https://issues.liferay.com/browse/LRQA-${ticket}" "${v}-qa-${ticket}"
		else
			echo "No"
		fi
	read -rsp $'Press any key to continue...\n' -n1 key
}

######################################################################################################################
##SUB MENUS###########################################################################################################
######################################################################################################################

poshiOption(){
	while :
	do
		clear
		testURL=$(cat $dir/test.$username.properties | grep "test.url=")
		cat<<EOF
========================================
POSHI $v
$testname
$testURL
----------------------------------------
Choose Your Destiny:

	(1) Poshi Runner      (p) Pull Request
	(2) Validate          (s) Run Test Suite
	(3) Pick New Test
	(4) Format Source
	(5) Set Test URL
	
	(q)uit - go back
----------------------------------------
EOF
	read -n1
	echo
	case "$REPLY" in
	"1")  poshiRunnerRun ;;
	"2")  poshiValidate ;;
	"3")  poshiSetTest ;;
	"4")  poshiFormat ;;
	"5")  poshiSetUrl ;;
	#"s")  poshiSuite ;;
	"p")  qaPullRequest ;;
	"Q")  echo "case sensitive!!" ;;
	"q")  break ;; 
	* )   echo "Not a valid option" ;;
	esac
done
}

branchMenu(){
	while :
	do
		clear
		if [ "$public" = "true" ]
		then
			public="public"
		fi

		cd $dir
		portalID="$(git log --pretty=format:'%H' -n 1)"
		gitBranch="$(git rev-parse --abbrev-ref HEAD)"
		cat<<EOF
============================================
$v $public

Git ID: $portalID
Git Branch: $gitBranch
--------------------------------------------
Please choose:

	(1) Build Bundle     (a) Add Known Issues
	(2) Clear Enviroment (f) Update FP
	(3) POSHI
	(4) Deploy Plugins
	(5) Git Info Template

	(q)uit - Main Menu
--------------------------------------------
EOF
	read -n1
	echo
	case "$REPLY" in
	"1")  bundleBuild ;;
	"2")  clearEnv ;;
	"3")  poshiSetTest ; poshiOption ;;
	"4")  pluginsDeploy ;;
	"5")  gitInfoTemplate ;;
	"a")  addKnownIssues ;;
	"f")  updateFixPriorities ;;
	"Q")  echo "case sensitive!!" ;;
	"q")  echo "quit" 
		  break  ;; 
	* )   echo "Not a valid option" ;;
	esac
	done
}

######################################################################################################################
##MAIN MENU###########################################################################################################
######################################################################################################################

while :
do
	clear
	cat<<EOF

Liferay Portal QA Tool    
=====================================================
Main Menu
-----------------------------------------------------
Hello $name 
Please choose a branch version:

	(1) Master        (r) 7.0.x
	(2) ee-6.2.x      (w) Master Wildfly
	(3) ee-7.0.x
	(4) ee-6.1.x
	(5) ee-6.2.10
	(6) Master EE
	(7) 6.2.x

	(q)uit
-----------------------------------------------------
EOF
	read -n1
	echo
	case "$REPLY" in
	"1")  dir=$masterSourceDir bundleDir=$masterBundleDir pluginsDir=$masterPluginsDir v="master" db=$masterDB port=$masterPort jb="master" public="true" wf="false" branchMenu ;;
	"2")  dir=$ee62xSourceDir bundleDir=$ee62xBundleDir pluginsDir=$ee62xPluginsDir v="ee-6.2.x" db=$ee62xDB port=$ee62xPort jb="ee62x"  branchMenu ;;
	"3")  dir=$ee70xSourceDir bundleDir=$ee70xBundleDir pluginsDir=$ee70xPluginsDir v="ee-7.0.x" db=$ee70xDB port=$ee70xPort jb="ee70x" branchMenu ;;
	"4")  dir=$ee61xSourceDir bundleDir=$ee61xBundleDir pluginsDir=$ee61xPluginsDir v="ee-6.1.x" db=$ee61xDB port=$ee61xPort jb="ee61x" branchMenu ;;
	"5")  dir=$ee6210SourceDir bundleDir=$ee6210BundleDir pluginsDir=$ee6210PluginsDir v="ee-6.2.10" db=$ee6210DB port=$ee6210Port jb="ee6210"  branchMenu ;;
	"6")  dir=$eeMasterSourceDir bundleDir=$eeMasterBundleDir pluginsDir=$masterPluginsDir v="master" db=$eeMasterDB port=$eeMasterPort jb="master" branchMenu ;;
	"7")  dir=$ce62xSourceDir bundleDir=$ce62xBundleDir pluginsDir=$ce62xPluginsDir v="6.2.x" db=$ce62xDB port=$ce62xPort jb="62x"  branchMenu ;;
	"r")  dir=$ce70xSourceDir bundleDir=$ce70xBundleDir pluginsDir=$ce70xPluginsDir v="7.0.x" db=$ce70xDB port=$ce70xPort jb="70x" branchMenu ;;
	"l")  lpsConverter ;;
	"w")  dir=$masterSourceDir bundleDir=$masterBundleDir pluginsDir=$masterPluginsDir v="master" db=$masterDB port=$masterPort jb="master" public="true" wf="true" branchMenu ;;
	"Q")  echo "case sensitive!!" ;;
	"q")  echo "quit" 
		  exit ;; 
	* )   echo "Not a valid option" ;;
	esac
done
