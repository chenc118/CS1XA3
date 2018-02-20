#!/git-bash.exe

#Potential feature turning some of this stuff into HTML if -report flag in args?

# random variable, not sure if I'll use it
UPTODATE=$(git pull)


#----Find uncommitted changes I ----
#AKA feature # 1 adds the stuff form git status to the diff stuff


Changelog="changes.log" #var to change the file in the future if I ever use this thing again

#first sed cleans blank lines, second cleans mess in brackets, third cleans first line telling status of branch
STATUSCLEAN="/^ *$/d;/(*)/d;/^On branch*/,2d"
Test="/^ *$/d"

#sed '/^ *$/d' sourced from wikipedia on sed to clean empty lines
#sed '//,+#d' sourced from stackoverflow: https://stackoverflow.com/questions/4396974/sed-or-awk-delete-n-lines-following-a-pattern

rm changes.log

#flag to see if there's untracked files
untracked=$( git status | grep "Untracked files:" | wc -l )

Status=$(git status)


# clear changes.log
$( echo "The following files have not been committed" > "changes.log")

# if there are untracked files
if [ $untracked -eq 1 ]
then
	#adds untracked tag to untracked files, after getting them
	$( echo "$Status" | sed -e "$STATUSCLEAN;/Untracked files:/d;/:/d;s/^	/	untracked:  /g" > "changes.log" )
	STATUSCLEAN="$STATUSCLEAN;/Untracked files:/,\$d" # delete all after line sourced from https://stackoverflow.com/questions/5227295/how-do-i-delete-all-lines-in-a-file-starting-from-after-a-matching-line 
fi

# get other changes
$( echo "$Status" | sed "$STATUSCLEAN;/Changes to be committed:/d;/Changes not staged for commit:/d" >> "changes.log" )


#---- Find uncommitted changes II ----
#uses git diff prints in a cleaner style than default with lines numbered and all that

Diff=$( git diff )

$(echo "Current git diff:" >> changes.log)

#iterate over lines https://superuser.com/questions/284187/bash-iterating-over-lines-in-a-variable

#init some vars for the read loop

#if in code fragment of diff, will use different stuffs
Code="False"
RCodeCount="0" # count current line of code
ACodeCount="0"
#Numbers to count code line
RNum="0"
ANum="0"
#padding altered from the following https://stackoverflow.com/questions/4409399/padding-characters-in-printf
#literally just a bunch of spaces
Pad=$(printf '%0.1s' " "{1..60})
#length to pad the numbers
PadL=6

#iterate over the lines of the diff stuff
while read -r line; do
	#non code lines either of 5 types
	if [ "$Code" == "False" ]
	then
		#use multi sed command to get what exactly the non code line is
		Status=$(echo "$line" | sed -e "s/^diff --git.*/1/;s/^index.*/2/;s/^---.*/3/;s/^+++.*/4/;s/^@@.*/5/;s/[^1-5]/6/;s/\(.\).*/\1/;s/^$/6/")
		#1 = first line 2 = index objects 3 = --- 4 = +++ 5 = @@ aka start of code 6 = mode or something, too difficult to match easily
		if [ "$Status" -eq "5" ]
		then
			Code="True"
			RNum=$(echo "$line" | sed -e "s/^@@ -\([0-9]*\),.*/\1/")
			ANum=$(echo "$line" | sed -e "s/^@@ -[0-9]*,[0-9]* +\([0-9]*\),.*/\1/")
			RCodeCount=$(echo "$line" | sed -e "s/^@@ -[0-9]*,\([0-9]*\) .*/\1/")
			ACodeCount=$(echo "$line" | sed -e "s/^@@ -[0-9]*,[0-9]* +[0-9]*,\([0-9]*\).*/\1/")
			#TODO print stuff to changelog

		elif [ "$Status" -eq "4" ]
		then
			# dump the file name into the changelog
			$(echo >> changes.log)
			$(echo "$line" | sed -e "s/^+++ b\//File diff: /" >> changes.log)
		fi

	elif [ $Code == "True" ]
	then
		if [ $ACodeCount -eq 0 -a $RCodeCount -eq 0 ]
		then
			Code="False"
			#TODO everything else and determine what the code count must be equal to in order to switch out of this state
		else
			#Print lines, numbering etc
			Start=$(echo $line | sed -e "s/\(.\).*/\1/")
			if [ "$Start" = "+" ]
			then
				PadA=$(( $PadL - ${#ANum} ))
				$(printf '%*.*s%s|%*.*s%s|%s' 0 "$PadL" "$Pad" "" 0 "$PadA" "$Pad" "$ANum" "$line" >> changes.log)
				ANum=$(( $ANum + 1 ))
				ACodeCount=$(( $ACodeCount - 1 ))
			elif [ "$Start" = "-" ]
			then
				PadR=$(( $PadL - ${#RNum} ))
				$(printf '%*.*s%s|%*.*s%s|%s' 0 "$PadR" "$Pad" "$RNum" 0 "$PadL" "$Pad" "" "$line" >> changes.log)
				RNum=$(( $RNum + 1 ))
				RCodeCount=$(( $RCodeCount - 1 ))
			else
				PadR=$(( $PadL - ${#RNum} ))
				PadA=$(( $PadL - ${#ANum} ))
				$(printf '%*.*s%s|%*.*s%s|%s' 0 "$PadR" "$Pad" "$RNum" 0 "$PadA" "$Pad" "$ANum" "$line" >> changes.log)
				#increment decrement stuff
				RNum=$(( $RNum + 1 ))
				ANum=$(( $ANum + 1 ))
				RCodeCount=$(( $RCodeCount - 1 ))
				ACodeCount=$(( $ACodeCount - 1 ))

			fi
			
			$(echo >> changes.log) #to add newline


		fi

	fi

done <<< $Diff
#---- FIND TODO ----




