#!/bin/bash

pwd=$PWD

mergesort(){
    local array_string=$1
    local array=($array_string)

    local size=${#array[@]}

    if ((size>1)); then
        
        local first_half=(${array[@]:0:size/2})
        local second_half=(${array[@]:size/2:size-size/2})
        local first_half_string=$(mergesort "${first_half[*]}")
        first_half=($first_half_string)
        local second_half_string=$(mergesort "${second_half[*]}")
        second_half=($second_half_string)

        local f_start=0
        local s_start=0
        for((i=0; i<size; i++)); do
            local f_start_vala=${first_half[$f_start]}
            local s_start_vala=${second_half[$s_start]}
            local f_no=${f_start_vala#??}
            local s_no=${s_start_vala#??}
            if (((f_start<size/2) && (s_start<size-size/2))); then
                if ((10#$f_no < 10#$s_no)); then        # forcing base10 interpretation, else it was interpreting it as octal
                    array[$i]=$f_start_vala
                    ((f_start++))
                else
                    array[$i]=$s_start_vala
                    ((s_start++))
                fi
            elif ((f_start<size/2)); then
                array[$i]=$f_start_vala
                ((f_start++))
            else
                array[$i]=$s_start_vala
                ((s_start++))
            fi
        done
    fi
    echo "${array[*]}"
}

# COMBINE
combine(){
    echo "Roll_Number,Name" > main.csv
    declare -A main_array
    
    #storing names for roll numbers
    for file in *.csv
    do 
        i=0
        while read -r line
        do
            if [ $i -eq 0 ]; then
                ((i++))
                continue
            fi

            IFS=","
            data=($line)
            unset IFS

            roll_no="${data[0]}"
            roll_id="${roll_no:0:2}${roll_no:3}"    # stripping b from roll no
            main_array["$roll_id"]=${data[1]}
        done < $file
    done

    # sorting all roll numbers in main_array : sorted_Rollids
    declare -a Rollnos=${!main_array[@]}
    sorted_Roll_string=$(mergesort "${Rollnos[*]}")
    sorted_Rollids=($sorted_Roll_string)

    # adding roll no and name fields in main.csv
    for i in ${sorted_Rollids[@]}
    do
        echo ${i:0:2}B${i:2},${main_array["$i"]} >> main.csv
    done

    # creating a field for each exam and adding it to main.csv
    for file in *.csv
    do
        sed -i 's/\r//g' $file
        if [[ $file != "main.csv" ]]
        then
            # creating a dictionary of roll no and marks for this exam
            declare -A exam_marks
            while read -r line
            do
                IFS=","
                data=($line)
                unset IFS

                roll_no="${data[0]}"
                roll_id="${roll_no:0:2}${roll_no:3}"    # stripping b from roll no
                exam_marks["$roll_id"]=${data[2]}
            done < $file

            # creating the whole field by incorporating 'a' for those not present in this exam
            declare -a exam_field

            for Rollno in ${sorted_Rollids[@]}
            do
                if [[ "${exam_marks[$Rollno]}" ]]
                then
                    exam_field+=(${exam_marks[$Rollno]})
                else
                    exam_field+=("a")
                fi
            done

            # adding this created field in main.csv
            exam_name=${file%\.csv}

            echo $exam_name > exam_field.csv
            counter=0
            for rollno in ${sorted_Rollids[@]}
            do
                echo "${exam_field[$counter]}" >> exam_field.csv
                ((counter++))
            done

            cut -d "," -f 1,2 --output-delimiter="," main.csv > temp.csv
            paste -d ',' temp.csv exam_field.csv > temp1.csv
            cut -d "," -f 1,2 --output-delimiter="," --complement main.csv | sed 's/,$//' > temp2.csv
            paste -d "," temp1.csv temp2.csv > main.csv
            rm temp.csv temp1.csv temp2.csv
            rm exam_field.csv

            unset exam_marks
            unset exam_field
        fi
    done
}

#UPLOAD
function upload(){
    new_file=$1
    IFS="/"
    file_path_comp=($new_file)
    length=${#file_path_comp[@]}
    file_name=${file_path_comp[(( length-1 ))]}
    unset "file_path_comp[((length-1))]"
    source_loc="${file_path_comp[*]}"
    destination="$2"
    cd "$source_loc"
    cp "$file_name" "$destination/$file_name"
}

#TOTAL
total(){

    # determining how many exam data are there in main.csv currently - nexams
    declare -a faaltu_fields=("Roll_Number" "Name" "total")         # ***add all other statistics fields that you add
    top_row="$(head -1 main.csv)"

    IFS=","
    all_fields=($top_row)
    unset IFS

    nexams=0
    for i in ${all_fields[@]}
    do
        if [[ " ${faaltu_fields[@]} " =~ " $i " ]]; then
            :
        else
            ((nexams++))
        fi
    done

    # determining if total is already there or not
    if [[ " ${all_fields[@]} " =~ " total " ]]; then
        for ((i=0; i<${#all_fields}; i++)); do
            if [[ ${all_fields[$i]} == "total" ]]; then
                index_total=$i
                break
            fi
        done

        cut -d "," -f $((index_total+1)) --output-delimiter="," --complement main.csv > omg.csv
        cat omg.csv > main.csv
        rm omg.csv
    fi

    # using an awk file, sum all the required fields and append at the end of the line
    awk -v no_of_exams=$nexams -f total.awk main.csv > temp_total.csv   # -v flag: pass variable as an argument to awk file
    cat temp_total.csv > main.csv
    rm temp_total.csv
}

# GIT_INIT
git_init(){
    path_to_folder="$1"

    if [ -d "$path_to_folder" ]
    then
        git_remote=$path_to_folder
    else
        mkdir "$path_to_folder"
        git_remote=$path_to_folder
    fi

    # ensuring that git has been run for commits and checkout
    echo $git_remote > git_executed
}

# GIT_COMMIT
git_commit(){
    if [[ "$1" == "-m" ]]; then
        commit_message="$2"
    fi

    if [ -f "git_executed" ]
    then
        GIT_REMOTE=$(cat "git_executed")
        random_no=$(echo $(od -An -N10 /dev/urandom) | tr -d ' ' | tr -d '-' | awk '{print "1"$0}' | cut -c1-16)
        commit_hash=$random_no
        commit_folder=$(echo "commit$RANDOM")
        mkdir "$GIT_REMOTE/$commit_folder"
        echo $commit_hash > "$GIT_REMOTE/$commit_folder/commit_hash.txt"            # storing hash value of commit- commit_hash.txt
        echo $commit_message > "$GIT_REMOTE/$commit_folder/commit_message.txt"      # storing commit message- commit_message.txt
        
        # finding the last commit_hash
        cd $GIT_REMOTE
        if [ -f ".git_log" ]
        then
            last_commit_hash=$(cat .git_log | tail -1 | cut -d " " -f 1)
        else
            last_commit_hash="empty"
        fi
        cd "$pwd"

        # finding last commit folder
        if [[ "$last_commit_hash" != "empty" ]]; then
            cd "$GIT_REMOTE"
            folder_last_commit=$(find -type f -exec grep -l "$last_commit_hash" {} \; | grep -E "^\./commit" | cut -d "/" -f 2)
            cd "$pwd"
        else
            folder_last_commit="empty"
        fi

        # writing hash value and commit message to .git_log file
        echo "$commit_hash $commit_message" >> "$GIT_REMOTE/.git_log"

        # copy all items to the commit folder
        for i in *
        do
            # copy only files
            if [ -f "$i" ]; then
                cp "$i" "$GIT_REMOTE/$commit_folder/$i"
            fi
            rm -f "$GIT_REMOTE/$commit_folder/git_executed"
        done

        # checking which files were modified after last commit
        if [[ "$last_commit_hash" != "empty" ]]; then
            declare -a non_req_files=("commit_hash.txt" "commit_message.txt")
            cd "$GIT_REMOTE"
            diff -q "$folder_last_commit" "$commit_folder" | sed -n "/^Files .* differ$/p" > diff_data
            while read -r line
            do
                IFS="/"
                Line=($line)
                unset IFS

                Index=$((${#Line[@]}-1))
                a=${Line[$Index]}
                file_modified=${a% differ}
                if [[ ! " ${non_req_files[@]} " =~ " $file_modified " ]]; then
                    echo "$file_modified"
                fi
            done < "diff_data"
            rm diff_data
            cd "$pwd"
        else
            declare -a non_req_files=("commit_hash.txt" "commit_message.txt")
            cd "$GIT_REMOTE/$commit_folder"
            for i in *
            do
                if [[ " ${non_req_files[@]} " =~ " $i " ]]
                then
                    :
                else
                    # awk -F/ "BEGIN{no_fields=NF} {print $no_fields}"
                    # file_path_string="$i"
                    # IFS="/"
                    # file_path=($file_path_string)
                    # unset IFS
                    # ((index=${#file_path[@]}-1))
                    # echo "${file_path[$index]}"
                    echo "$i"
                fi
            done
            cd "$pwd"
        fi

    else
        echo "git: remote repository not initialized"
        echo "Try running git_init first"
    fi
}

# CHECKOUT BY MESSAGE
git_checkout_message(){
    commit_message="$1"
    if [ -f "git_executed" ]
    then
        GIT_REMOTE=$(cat "git_executed")

        cd "$GIT_REMOTE"
        find -type f -exec grep -l "$commit_message" {} \; | grep -E "^\./commit" | cut -d "/" -f 2 > all_commit_folders.txt
        no_of_folders=$(awk "END{print NR}" all_commit_folders.txt)

        if [ $no_of_folders -ne 1 ]
        then
            req_commit_folder=$(cat "all_commit_folders.txt" | head -1)
            rm all_commit_folders.txt
            
            # storing current pwd data in $GIT_REMOTE/latest and removing all files from pwd
            # so that latest doesn't get messed up by commit files through repeated checkouts
            if [ -d "latest" ]
            then
                :
            else
                mkdir -p "latest"
                cp -r "$pwd"/* "latest"
            fi

            cd "$pwd"
            for file in *
            do
                if [ -f "$file" ]; then
                    if [[ "$file" != "git_executed" ]]; then
                        rm "$file"
                    fi
                fi
            done

            # copying commit files to pwd
            cd "$GIT_REMOTE/$req_commit_folder"
            declare -a non_req_files=("commit_hash.txt" "commit_message.txt")
            
            for i in *
            do
                if [[ " ${non_req_files[@]} " =~ " $i " ]]
                then
                    :
                else
                    cp "$i" "$pwd/$i"
                fi
            done
            cd "$pwd"

        elif [ $no_of_folders -eq 0 ]
        then
            echo "git: Wrong commit message"
            rm all_commit_folders.txt
        else
            echo "Commit Message CONFLICT !"
            cat all_commit_folders.txt
            rm all_commit_folders.txt
        fi

    else
        echo "git: remote repository not initialized"
    fi
}

# CHECKOUT BY HASH
git_checkout_hash(){
    commit_hash="$1"
    if [ -f "git_executed" ]
    then
        GIT_REMOTE=$(cat "git_executed")

        cd "$GIT_REMOTE"
        find -type f -exec grep -l "$commit_hash" {} \; | grep -E "^\./commit" | cut -d "/" -f 2 > all_commit_folders.txt
        no_of_folders=$(awk "END{print NR}" all_commit_folders.txt)

        if ((no_of_folders==1))
        then
            req_commit_folder=$(cat "all_commit_folders.txt" | head -1)
            rm all_commit_folders.txt
            # storing current pwd data in $GIT_REMOTE/latest and removing all files from pwd
            # so that latest doesn't get messed up by commit files through repeated checkouts
            if [ -d "latest" ]
            then
                :
            else
                mkdir latest
                cp -r "$pwd"/* "latest"
            fi
            
            cd "$pwd"
            for file in *
            do
                if [ -f "$file" ]; then
                    if [[ "$file" != "git_executed" ]]; then
                        rm "$file"
                    fi
                fi
            done

            # copying commit files to pwd
            cd "$GIT_REMOTE/$req_commit_folder"
            declare -a non_req_files=("commit_hash.txt" "commit_message.txt")
            
            for i in *
            do
                if [[ " ${non_req_files[@]} " =~ " $i " ]]
                then
                    :
                else
                    cp "$i" "$pwd/$i"
                fi
            done
            cd "$pwd"
        elif ((no_of_folders==0))
        then
            echo "git: Please enter a valid commit id"
            rm all_commit_folders.txt
        else
            echo "git: Commit HASH CONFLICT !"
            cat all_commit_folders.txt
            rm all_commit_folders.txt
        fi

    else
        echo "git: remote repository not initialized"
    fi
}

git_log(){
    GIT_REMOTE=$(cat "git_executed")
    cd "$GIT_REMOTE"
    echo "Starting from.."
    cat .git_log
    echo "..till here"
    cd "$pwd"
}

# revert back to main branch, i.e. move to the original state of directory
git_main(){
    if [ -f "git_executed" ]
    then
        GIT_REMOTE=$(cat git_executed)

        cd "$GIT_REMOTE"

        if [ -d "latest" ]
        then
            rm "$pwd"/*
            cd latest
            cp ./* "$pwd"

            echo "Original Directory restored"
        else
            echo "No checkouts have been made yet"
        fi

        cd "$pwd"

    else
        echo "git: remote not found"
    fi
}

# update marks for a student
update(){
    # array of exams in main.csv
    declare -a not_to_include=("Roll_Number" "Name" "total")        ##### more stats to be included
    top_row="$(sed -n "1p" main.csv)"
    IFS=","
    Top_row=($top_row)
    unset IFS

    # first storing the rollno: name dictionary from main.csv
    declare -A roll_name_dict
    while read -r line
    do
        IFS=","
        line_items=($line)
        unset IFS

        rollno=${line_items[0]}
        name=${line_items[1]}

        roll_name_dict["$rollno"]="${name}"
    done < "main.csv"

    # Keep taking entries as long as user gives
    enter="y"                                       # bool for the while loop
    while [[ "$enter" == "y" ]]
    do
        # Taking input of the updates from the user
        echo -n "Enter the roll number of the student: "
        read Roll_no
        if [[ $Roll_no == [0-9][0-9][bB][0-9]* ]]; then
            RollBno="${Roll_no[@]:0:2}B${Roll_no[@]:3}"
            if [[ " ${!roll_name_dict[@]} " =~ " $RollBno " ]]; then
                echo -n "Enter the name of the corresponding student: "
                read Name
                if [[ ${roll_name_dict[$RollBno],,} =~ ^${Name,,}$ ]]; then     # ***case insensitive match
                    echo -n "Which exam do you want to change marks for? "
                    read exam
                    for ((j=0; j<${#Top_row}; j++))
                    do
                        if [[ "${Top_row["$j"]}" == "$exam" ]]; then
                            index=$((j+1))
                            break
                        fi
                    done
                    #change the marks
                    nf=${#Top_row}
                    echo -n "Enter the new marks: "
                    read marks
                    awk -F, -v marks="$marks" -v ind="$index" -v nf="$nf" -v RollBno="$RollBno" -v Name="${roll_name_dict[$RollBno]}" '
                        BEGIN { OFS="," }
                        ($1 == RollBno && $2 == Name) {
                            $ind = marks
                        }
                        { print }
                    ' main.csv > temp.csv && mv temp.csv main.csv

                    # changing the corresponding exam file
                    name=${roll_name_dict[$RollBno]}
                    sed -i "/^$RollBno,$name,/ s/.*/$RollBno,$name,$marks/" "$exam.csv"

                    echo "||$exam marks have been updated for $Name($Roll_no)||"
                else
                    echo "The given credentials don't match"
                fi
            else
                # Adding a new record
                echo -n "The given roll number doesn't exist. Do you want to add a new record?(y/n)"
                read new_rec
                if [[ "$new_rec" == "y" ]]; then
                    add_new
                fi
            fi
        else
            echo "Please enter a valid format: xxBx...x"
        fi

        
        # ASK FOR THE NEXT LOOP ITERATION
        echo ''
        echo -n "Want to keep updating?(y/n)"
        read enter
    done

    # updating the total function           # ***other functions also
    if [[ " ${Top_row[@]} " =~ " total " ]]; then
        total
    fi
}

add_new(){
    # first storing the rollno: name dictionary from main.csv
    declare -A roll_name_dict
    while read -r line
    do
        IFS=","
        line_items=($line)
        unset IFS

        rollno=${line_items[0]}
        name=${line_items[1]}

        roll_name_dict["$rollno"]="${name}"
    done < "main.csv"

    # Taking inputs
    echo ''
    echo "!! Adding a new record !!"
    echo "Please provide the following details:-"
    echo -n "Roll Number: "; read Roll_no
    if [[ $Roll_no == [0-9][0-9][bB][0-9]* ]]; then
        RollBno="${Roll_no[@]:0:2}B${Roll_no[@]:3}"
        if [[ "${roll_name_dict["RollBno"]}" ]]; then
            echo "The given Roll Number already exists. Try using the update command instead.."
        else
            # record_string="$RollBno"
            
            echo -n "Name of the student: "; read Name
            # record_string+=",$Name"

            # Adding data for each exam in its exam file
            for file in *.csv
            do
                if [[ "$file" != "main.csv" ]]; then
                    exam_name=${file%\.csv}
                    echo -n "Marks for $exam_name (Please enter 'a' if the student was absent in this exam): "; read marks
                    if [[ "$marks" != "a" ]]; then              # Don't add if absent
                        echo "$RollBno,$Name,$marks" >> $file
                    fi
                fi
            done

            # updating main.csv
            top_row="$(sed -n "1p" main.csv)"
            IFS=","
            Top_row=($top_row)
            unset IFS

            if [[ " ${Top_row[@]} " =~ " total " ]]
            then
                combine
                total
            else
                combine
            fi

            # Confirm completion
            echo "||New records added for $Name($RollBno)||"
        fi
    else
        echo "Please enter a valid roll number format: xxBx...x"
    fi
}

# Stats
stats(){
    top_row="$(head -1 main.csv)"
    IFS=","
    Top_row=($top_row)
    unset IFS
    # checking if total is there or not
    if [[ " ${Top_row[@]} " =~ " total " ]]; then
        :
    else
        total
    fi

    exam="$1"
    # finding which column the data for exam lies in
    col_index=0
    for ((i=0; i<${#Top_row}; i++))
    do
        if [[ "${Top_row["$i"]}" == "$exam" ]]; then
            ((col_index = i + 1))
            break
        fi
    done
    # if that exam doesn't lie in main.csv but is in the directory
    if [ $col_index -eq 0 ]; then
        if [ -f "$exam.csv" ]; then
            combine
        else
            echo "ERROR: No exam named $exam"
        fi
    else
        #invoking an awk script for displaying various stats
        awk -v col_index=$col_index -v exam=$exam -f stats.awk main.csv
    fi
}


#####################################################
# Calling various functions in this section         #
#####################################################


if [ -f "main.csv" ]; then
    Top_row="$(head -1 main.csv)"
    IFS=","
    ALL_fields=($Top_row)
    unset IFS
    if [[ "$1" == "combine" ]]; then

        if [[ " ${ALL_fields[@]} " =~ " total " ]]
        then
            combine
            total
        else
            combine
        fi
    fi
else
    combine
fi

if [[ "$1" == "upload" ]]
then
    upload "$2" "$PWD"
fi

if [[ "$1" == "total" ]]
then
    total
fi

if [[ "$1" == "git_init" ]]
then
    git_init "$2"
fi

if [[ "$1" == "git_commit" ]]
then
    if [ $# -eq 1 ]; then
        echo -n "Please enter the commit message: "
        read message
        git_commit "-m" "$message"
    elif [[ "$2" == "-m" ]]
    then
        message="$3"
        git_commit "-m" "$message"              #****not tested
    fi
fi

if [[ "$1" == "git_checkout" ]]
then
    if [ $# -eq 2 ]
    then
        if [[ "$2" == "-m" ]]; then
            echo -n "Please enter the commit message: "
            read message
            git_checkout_message "$message"
        else
            git_checkout_hash "$2"
        fi
    elif [[ "$2" == "-m" ]]; then
        message="$3"
        git_checkout_message "$message"
    else
        echo "Valid Formats:"
        echo "git_checkout -m '<<commit_message>>'"
        echo "git_checkout <<hash_value>>"
    fi
fi

if [[ "$1" == "git_log" ]]
then
    git_log
fi

if [[ "$1" == "git_main" ]]
then
    git_main
fi

if [[ "$1" == "update" ]]
then
    update
fi

# Grading stats- mean, median, standard deviation
if [[ "$1" == "grading_stats" ]]
then
    if [ $# -eq 2 ]; then
        exam="$2"
        stats $exam
        python3 plot.py $exam
    elif [ $# -eq 1 ]; then
        echo -n "Please specify the exam you want the statistics for: "
        read exam
        stats $exam
        python3 plot.py $exam
    fi
fi

# Grading stats for the course total
if [[ "$1" == "overall_stats" ]]
then
    arg="total"
    stats $arg
    python3 plot.py total
fi

## For GUI file, just invoking stats function
if [[ "$1" == "GUIstats" ]]; then
    stats "$2"
fi

# Getting records for a particular student
if [[ "$1" == "get_record" ]]
then
    echo "Please provide the following details:-"
    echo -n "Roll Number: "; read Rollno
    echo "The marks for various exams for Roll Number $Rollno are listed below:"
    for file in *.csv
    do
        if [[ "$file" != "main.csv" ]]; then
            exam_name=${file%\.csv}

            marks=$(python3 Get_record_for_exam.py $exam_name $Rollno)
            
            echo "$exam_name: $marks"
        fi
    done
    python3 Get_record.py $Rollno
fi

# Generate Report Card
if [[ "$1" == "report_card" ]]
then
    :
fi

# Starting the GUI
if [[ "$1" == "start_gui" ]]
then
    python3 GUI.py
fi
