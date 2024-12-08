import numpy as np
import tkinter as tk
from tkinter import ttk
import subprocess
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import matplotlib.pyplot as plt
import re
import os


def find_stats(exam_name, window):
    # Run the script and capture the output
    result = subprocess.run(["bash", "submission.sh", "GUIstats", exam_name], capture_output=True, text=True)
    stdout_output = result.stdout  # Captured stdout output

    text_label = tk.Label(window, text=stdout_output, anchor="w", font=("Arial",16))
    # text_label.pack(anchor="w", padx=200)
    text_label.grid(row=1, rowspan=2, column=0, columnspan=3)
    
    generate_plot(exam_name, window)

def generate_plot(exam_name, window):
    # Frame for the plot of overall stats
    plot_frame = ttk.Frame(window)
    # plot_frame.pack(anchor="w", padx=100)
    plot_frame.grid(row=4, rowspan=4, column=0, columnspan=3)
    # Retrieving data from main.csv for the exam_name
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
    
    # generating the plot
    fig, ax = plt.subplots()
    
    # plot
    ax.scatter(Roll_list, marks_array, color='blue', label='Marks vs Roll Number')
    
    ax.axhline(y=mean_mark, color='green', linestyle='-', label='Mean')
    ax.axhline(y=median_mark, color='red', linestyle='-', label='Median')
    ax.axhline(y=mean_mark + std_dev, color='orange', linestyle='--', label='Mean + Std Dev')
    ax.axhline(y=mean_mark - std_dev, color='orange', linestyle='--', label='Mean - Std Dev')
    
    # labels and legend
    ax.set_xlabel('Roll Number')
    ax.set_ylabel('Marks')
    ax.legend()
    
    # Create a FigureCanvasTkAgg widget
    canvas = FigureCanvasTkAgg(fig, master=plot_frame)
    canvas.draw()
    # canvas.get_tk_widget().pack(side="left", fill="y")
    canvas.get_tk_widget().grid(row=4, rowspan=4, column=0, columnspan=3)
    # We use the grid() method of the FigureCanvasTkAgg widget to place the Matplotlib plot in the first row and column of the plot_frame frame
    # The sticky=tk.NSEW option ensures that the plot widget expands to fill the available space in the frame both horizontally and vertically.
    # tk.W keeps it to the left
    
def new_exam_stats(exam_name):
    new_window = tk.Toplevel(root)
    new_window.title(exam_name)
    
    # Heading
    heading = tk.Label(new_window, text=str(exam_name).capitalize(), anchor="center", font=("Georgia", 24, "bold"))
    # heading.pack(side="top", pady=50)
    heading.grid(row=0, column=0, columnspan=2)
    
    find_stats(exam_name, new_window)


def modify_database():
    
    def combine():
        subprocess.run(['bash', 'submission.sh', 'combine'], shell=True, stdout=subprocess.STDOUT, stderr=subprocess.STDOUT)

    def upload():
        file_path = enter_file_path.get()
        subprocess.run(['bash', 'submission.sh', 'upload', file_path], shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def total():
        subprocess.run(['bash', 'submission.sh', 'total'], shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    modify_window = tk.Toplevel(root)
    modify_window.title("Database Management")
    
    #Combine
    command1 = tk.Label(modify_window, text="Combine all the csv files into main.csv:")
    
    if os.path.exists("main.csv"):
        with open("main.csv", "r") as f:    # exams included in main.csv
            toprow_string = f.readline().strip()
            toprow_list = toprow_string.split(",")
    else:
        toprow_list = []
    not_include=["Roll_Number", "Name", "total"]
    exam_list = [x for x in toprow_list if x not in not_include]
    
    pwd = os.getcwd()                   # all exams in directory
    pattern = r"^.*\.csv$"
    file_list = []
    for filename in os.listdir(pwd):
        if re.match(pattern, filename) and str(filename) != "main.csv":
            file_list.append(filename)
    
    lenth = max(len(exam_list), len(file_list))
    
    exam_entries = tk.Text(modify_window, width=10, height=lenth, borderwidth=2, relief="solid")
    exam_entries_content = '\n'.join(exam_list)
    exam_entries.insert(tk.END, exam_entries_content)
    exam_entries.config(state=tk.DISABLED)  #Disable editing
    
    file_entries = tk.Text(modify_window, width=10, height=lenth, borderwidth=2, relief="solid")
    file_entries_content = '\n'.join(file_list)
    file_entries.insert(tk.END, file_entries_content)
    file_entries.config(state=tk.DISABLED)  #Disable editing
    
    button1 = tk.Button(modify_window, text="COMBINE", command=lambda: combine())
    
    command1.grid(row=0, column=0)
    exam_entries.grid(row=0, column=1)
    file_entries.grid(row=0, column=2)
    button1.grid(row=0, column=3)
    
    
    #Upload
    command2 = tk.Label(modify_window, text="Upload a new .csv file to the current directory:")
    
    enter_file_path = tk.Entry(modify_window)
    
    button2 = tk.Button(modify_window, text="UPLOAD", command=lambda: upload())
    
    command2.grid(row=1, column=0)
    enter_file_path.grid(row=1, column=1, columnspan=2)
    button2.grid(row=1, column=3)
    
    
    #Total
    command3 = tk.Label(modify_window, text="Create a field for total marks of each student:")
    
    button3 = tk.Button(modify_window, text="TOTAL", command=lambda: total())
    
    command3.grid(row=2, column=0)
    button3.grid(row=2, column=3)

    
def view_student_performance():
    def show_performance():
        Rollno=text_box1.get()
        RollBno = Rollno[0:2] + "B" + Rollno[3:]
        with open("main.csv", "r") as f:
            toprow_string = f.readline().strip()
            toprow_list = toprow_string.split(",")
        not_include=["Roll_Number", "Name", "total"]
        exam_list = [x for x in toprow_list if x not in not_include]
        
        for i, exam in enumerate(exam_list):
            result = subprocess.run(['python3', 'Get_record_for_exam.py', exam, RollBno], capture_output=True, text=True)
            stdout_output = result.stdout.strip()  # Captured stdout output
            text_to_be_put = exam + ": " + stdout_output
            labelL = tk.Label(student_window, text=text_to_be_put)
            labelL.grid(row=(3+i), column=0)
        
        # Call Get_record.py to generate the plot and capture the output
        process = subprocess.Popen(['python3', 'Get_record.py', RollBno], stdout=subprocess.PIPE)
        output, _ = process.communicate()
    
    student_window = tk.Tk()
    student_window.title("Student Record")
    
    # define a frame on top for roll no and name
    custom_font2=tk.font.Font(size=20)
    
    label1 = tk.Label(student_window,  text="Roll Number: ", font=custom_font2)
    text_box1 = tk.Entry(student_window, font=custom_font2)
    label1.grid(row=1, column=1)
    text_box1.grid(row=1, column=2)
    
    find_button = tk.Button(student_window, text="Show Performance", command=lambda: show_performance(), font=custom_font2)
    find_button.grid(row=2, column=1, columnspan=2)
    
    

def git():
    def git_init():
        path = path_init.get()
        subprocess.call(['./submission.sh', 'git_init', path])
    def git_commit():
        mess = message.get()
        subprocess.call(['./submission.sh', "git_commit", "-m", mess])
    def git_checkout_hash():
        hash_no = textboxc1.get()
        subprocess.call(['./submission.sh', "git_checkout", hash_no])
    def git_checkout_message():
        checkout_message = textboxc2.get()
        subprocess.call(['./submission.sh', "git_checkout", "-m", checkout_message])
    def git_main():
        subprocess.call(['./submission.sh', 'git_main'])
    def git_log():
        logg = subprocess.run(['bash', 'submission.sh', 'git_log'], capture_output=True, text=True)
        new_text = logg.stdout
        # Clear the current text in the Text widget
        log_text.delete('1.0', tk.END)
        # Insert new text into the Text widget
        log_text.insert(tk.END, new_text)
        
    
    gitw = tk.Tk()
    gitw.title("Vesion Control System")
    
    path_init = tk.Entry(gitw)
    path_init.grid(row=0, column=0)
    buttona = tk.Button(gitw, text="git_init", command=lambda: git_init())
    buttona.grid(row=0, column=1, columnspan=2)
    
    message = tk.Entry(gitw)
    buttonb = tk.Button(gitw, text="git_commit", command=lambda: git_commit())
    message.grid(row=1, column=0)
    buttonb.grid(row=1, column=1, columnspan=2)
    
    labelc1 = tk.Label(gitw, text="Checkout by hash: ")
    labelc2 = tk.Label(gitw, text="Checkout by message: ")
    textboxc1 = tk.Entry(gitw)
    textboxc2 = tk.Entry(gitw)
    buttonc1 = tk.Button(gitw, text="git_checkout by hash", command=lambda: git_checkout_hash())
    buttonc2 = tk.Button(gitw, text="git_checkout by message", command=lambda: git_checkout_message())
    # placing them
    labelc1.grid(row=2, column=0)
    textboxc1.grid(row=2, column=1)
    buttonc1.grid(row=2, column=2, columnspan=2)
    labelc2.grid(row=3, column=0)
    textboxc2.grid(row=3, column=1)
    buttonc2.grid(row=3, column=2, columnspan=2)

    buttond = tk.Button(gitw, text="git_main", command=lambda: git_main())
    buttond.grid(row=5, column=0, columnspan=2)
    
    label_log = tk.Label(gitw, text="Git Log: ")
    label_log.grid(row=4, column=0)
    log = subprocess.run(['bash', 'submission.sh', 'git_log'], capture_output=True, text=True)
    stdout_output = log.stdout
    
    log_text = tk.Text(gitw, borderwidth=2, relief="solid")
    log_text.insert(tk.END, stdout_output)
    log_text.grid(row=4, column=1)
    
    refresh_log = tk.Button(gitw, text="Refresh Log", command=lambda: git_log())
    refresh_log.grid(row=4, column=2, columnspan=2)    


#####################################################################
# Create the main window
#####################################################################

root = tk.Tk()
root.title("Bash Grader")

# Heading
heading = tk.Label(root, text="Overall Course Statistics", anchor="nw", font=("Georgia", 20, "bold"))
# heading.pack(anchor="nw", padx=200, pady=30)
heading.grid(row=0, column=0, columnspan=2)

# Adding buttons for other exam stats in top right corner
right_heading = tk.Label(root, text="Statistics", anchor="ne", font=("Georgia", 18, "bold"))
# right_heading.pack(side="top", anchor="e", padx=100, pady=20)
right_heading.grid(row=0, column=3)
# creating button frame
button_frame = ttk.Frame(root)
# button_frame.pack(side="right", anchor="ne", fill="y", padx=100)
button_frame.grid(row=1, rowspan=4, column=3)
# creating buttons for each exam
with open("main.csv", "r") as f:
    toprow_string = f.readline().strip()
    toprow_list = toprow_string.split(",")
not_include=["Roll_Number", "Name", "total"]
exam_list = [x for x in toprow_list if x not in not_include]

custom_font1 = tk.font.Font(size=16)

for i, exam in enumerate(exam_list):
    button = tk.Button(button_frame, text=str(exam).capitalize(), command=lambda t=exam: new_exam_stats(t), font=custom_font1)
    # button.pack(side="top", pady=10, fill="x")
    button.grid(row=(i+1), column=3)

# Insert modify button for database modifications
custom_font = tk.font.Font(size=18)
button2 = tk.Button(root, text="\nModify Database\n", command=lambda: modify_database(), font=custom_font)
# button2.pack(side="right", anchor="e", padx=20, pady=50)
button2.grid(row=8, column=3)

# Insert git commands button
button4 = tk.Button(root, text="\nGit Version Control\n", command=git, font=custom_font)
# button4.pack(side="bottom", anchor="s", pady=50, fill="y")
button4.grid(row=8, column=0)

# Insert view student performance button for new window
button3 = tk.Button(root, text="\nView Student Performance\n", command=view_student_performance, font=custom_font)
# button3.pack(side="bottom", anchor="sw", padx=50, pady=50, fill="y")
button3.grid(row=8, column=1, columnspan=2)

# Run the function for adding outputs to the widgets for total stats
find_stats("total", root)



root.mainloop()