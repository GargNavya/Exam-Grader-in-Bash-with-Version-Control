import pandas as pd
import os
import re
import sys

def for_exam(exam_name, RollBno):
    
    exam = str(exam_name).capitalize()
    
    # Reading the csv file
    filename = f"{exam_name}.csv"
    
    df = pd.read_csv(filename)
    required_record = df[df["Roll_Number"] == RollBno]
    # If absent in the exam
    if required_record.empty:
        return "Absent"
    else:
        df.set_index('Roll_Number', inplace=True)
        marks = float(df.loc[RollBno, 'Marks'])
        return marks
    
Rollno=sys.argv[2]
RollBno = Rollno[0:2] + "B" + Rollno[3:]

exam_name=sys.argv[1]

marks = for_exam(exam_name, RollBno)

print(marks)