BEGIN{
    FS=",";
    sum=0;
    sum_square=0;
    absent_students=0;
    total_std=0;
}
(NR!=1){
    if (NF!=0){
        total_std += 1;
    }
    if($col_index != "a"){
        sum += $col_index;
        sum_square += $col_index*$col_index;
        array[NR] = $col_index;
    }else{
        absent_students += 1;
        array[NR] = 0;
    }
}
END{
    n = total_std;
    Average = (sum+0.0)/(n+0.0);
    
    Std_dev = sqrt((sum_square+0.0)/(n+0.0)-Average*Average);

    # asorti(array, key_arr);
    # counter=1;
    # for(i in key_arr){
    #     sorted_array[counter] = array[key_arr[i]];
    #     counter += 1;
    # }

    asort(array, sorted_array, "@val_num_desc");
    # sorts the array into sorted_array and sets the indices from 1,2,3..and so on

    if(n%2==1){
        Median = sorted_array[(n+1)/2];
    }else{
        Median = (sorted_array[n/2] + sorted_array[(n/2)+1])/2.0;
    }

    if(exam != "total"){
        printf "The relevant statistics for %s are:\n", exam;
    }
    printf "Mean: %f\n", Average;
    printf "Median: %f\n", Median;
    printf "Standard Deviation: %f\n", Std_dev;
    if(exam != "total"){
        printf "\nNo. of students not appeared: %d\n", absent_students;
    }
}