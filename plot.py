import sys
import numpy as np
import matplotlib.pyplot as plt

# Retrieving data from main.csv for the exam_name
exam_name = sys.argv[1]
Roll_list = []
marks_list = []
with open("main.csv", "r") as f:
    exam_string = f.readline().strip()
    exam_list = exam_string.split(",")
    
    index_of_exam = exam_list.index(exam_name)
    
    for line in f:
        Line = line.split(",")
        if Line[index_of_exam] == "a":
            marks = 0
        else:
            marks = float(Line[index_of_exam])
        
        marks_list.append(marks)
        
        Roll_list.append(Line[0])

marks_array = np.array(marks_list)

# Calculate statistics
mean_mark = np.mean(marks_array)
median_mark = np.median(marks_array)
std_dev = np.std(marks_array)

# Plot
plt.scatter(Roll_list, marks_array, color='blue', label='Marks vs Roll Number')

# Plotting horizontal lines for mean, median, and standard deviation
plt.axhline(y=mean_mark, color='green', linestyle='-', label='Mean')
plt.axhline(y=median_mark, color='red', linestyle='-', label='Median')
plt.axhline(y=mean_mark + std_dev, color='orange', linestyle='--', label='Mean + Std Dev')
plt.axhline(y=mean_mark - std_dev, color='orange', linestyle='--', label='Mean - Std Dev')

# Adding labels and legend
plt.xlabel('Roll Number')
plt.ylabel('Marks')
plt.legend()

plt.title(exam_name.capitalize())

plt.show()