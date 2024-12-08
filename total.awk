BEGIN {
    FS = ",";
    OFS = ",";
}
(NR == 1){
    print $0, "total";
}
(NR != 1){
    sum = 0;
    for (i = 3; i < 3 + no_of_exams; i++) {
        if($i != "a"){
            value = strtonum($i);
            sum = sum + value;
        }
    }

    print $0, sum;
}