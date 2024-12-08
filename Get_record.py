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
        # print(f"{exam}:", "Absent")
        return 0, 0
    else:
        df.set_index('Roll_Number', inplace=True)
        marks = float(df.loc[RollBno, 'Marks'])
        
        highest_marks = df['Marks'].max()
        student_percentage=(marks / highest_marks) * 100
        
        # print(f"{exam}:", marks, f"(Highest = {highest_marks})")
        return marks, student_percentage


# print("Please provide the following details:-")
# Rollno = input("Roll Number: ")
Rollno = sys.argv[1]
RollBno = Rollno[0:2] + "B" + Rollno[3:]

total = 0
comparison = {}

#Start printing
# print(f"The marks for various exams for Roll Number {RollBno} are listed below:")

pwd = os.getcwd()
pattern = r"^.*\.csv$"
for filename in os.listdir(pwd):
    if re.match(pattern, filename) and str(filename) != "main.csv":
        exam_name = str(filename)[:-4]
        marks, student_percentage = for_exam(exam_name, RollBno)
        total += marks
        comparison[exam_name] = student_percentage

# print("Total Marks:", total)

# Plotting comparison

import matplotlib.pyplot as plt

keys = list(comparison.keys())
values = list(comparison.values())

plt.bar(keys, values)
plt.ylim(0, 100)

plt.xlabel('Exams')
plt.ylabel('Marks as percentage of highest marks')
plt.title("Relative Performance")

plt.show()