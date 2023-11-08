#!/opt/local/bin/python
# This script create the AMSTer Toolbox Organizer. 
# The widget creation are dynamic in this script.
#
# Parameters : - display number
#
# Dependencies:
#	- pyqt6 python package
#
# New in Distro V 1.0:		-
#				V 2.0: Add display number as argument because cmd `who` will not work in backround
#						Comment all print to keep terminal clean
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# Mja (c) 2022/10/05 - 
#-----------------------------------------------------------------------------------------------------




import re, subprocess, platform, os, sys
import subprocess,  shlex
from PyQt6.QtWidgets import *
from PyQt6.QtGui import QFileSystemModel
from PyQt6.QtCore import pyqtSlot,  QModelIndex, QSize
from Ui_main_window_man import Ui_MainWindow, button_l1, button_l2, button_l3

def setupScreen(display_number):
	platform_str = str(platform.uname())
	if re.search("Linux", platform_str):
		display_var = subprocess.Popen("echo ${DISPLAY}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
		display_var = display_var[0].decode('ascii')
		display_var = re.search(r":\d+\.\d", display_var)[0]
		display_number = re.search(r":\d+\.\d", display_number)[0]
		#print("display read by who -m = {}".format(display_number))
		if str(display_var) != str(display_number):
			#print("export display variable")
			cmd = "export DISPLAY={}".format(display_number)
			#print(cmd)
			os.environ['DISPLAY'] = display_number



dir_path = subprocess.Popen("pwd", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
dir_path = dir_path[0].decode('ascii')


class MainWindow(QMainWindow,  Ui_MainWindow):


	def __init__(self, parent=None):
		super(MainWindow,  self).__init__(parent)
		self.setupUi(self)
		self.model = QFileSystemModel()
		self.model.setRootPath(dir_path)

		self.lineEdit_FROM.setText("${HOME}")
		self.pushButton_EXEC.setStyleSheet("background-color : coral")
		self.actionOpen_file.triggered.connect(self.openConfigFile)
	
		k = 0 # Initialise a counter used to manage position of horizontal layout in the main vertical layout of the window 
		for i in range(1,4,1):	# Loop through 3 dictionary (i = index for each line and the number of dictionary)
		
			nb_button = len(globals()["button_l" + str(i)])
			max_button = self.max_button
			cu_hl = 0
			cu_hl_mem = 0
			# #print("incermentation {}".format(i))
			
			# Create another counter for columnView
			j = 100 + 1
			


			# Manage horizontal layouts for this set of buttons
			nb_horizLayout = 1 + int(nb_button/max_button) # max 10 button on same line
			#print("Need to create {} horizontal layout".format(nb_horizLayout))
			for i_hl in range(0, nb_horizLayout, 1):
				# #print("create Layout: self.horizontalLayout_{}{}".format(str(i_hl), str(i)))
				globals()["self.horizontalLayout_" + str(i_hl)+ str(i)] = QHBoxLayout()
				globals()["self.horizontalLayout_" + str(i_hl) + str(i)].setContentsMargins(10, 1, 10, 1)
				globals()["self.horizontalLayout_" + str(i_hl) + str(i)].setSpacing(0)
				globals()["self.horizontalLayout_" + str(i_hl) + str(i)].setObjectName("horizontalLayout_{}{}".format(str(i_hl), str(i)))
	

			# Loop through each button
			nb_button_add = 0
			nb_button_add_line = 0
			for key, value in globals()["button_l" + str(i)].items():

				# Manage maximum button per line
				nb_button_add += 1
				nb_button_add_line += 1
				cu_hl = int((nb_button_add - 1)/max_button)
				if (cu_hl != cu_hl_mem):
					nb_button_add_line = 0
# 					spacerItem = QSpacerItem(40, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
# 					globals()["self.horizontalLayout_" + str(cu_hl) + str(i)].addItem(spacerItem)
				cu_hl_mem = cu_hl


				# Do not draw the button if we want a space
				if re.search(r"SPACE_\d+", key):
					for i_space in range(nb_button_add_line, (max_button+2), 1):
						spacerItem = QSpacerItem(40, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
						globals()["self.horizontalLayout_" + str(cu_hl) + str(i)].addItem(spacerItem)
					continue
				# Create and Add Button
				globals()["self.pushButton_"+str(key)] = QPushButton(self.centralWidget)
				globals()["self.pushButton_"+str(key)].setMinimumSize(QSize(100, 35))
				globals()["self.pushButton_"+str(key)].setObjectName("pushButton_{}".format(key))
				globals()["self.pushButton_"+str(key)].setText(str(key))
				globals()["self.horizontalLayout_" + str(cu_hl) + str(i)].addWidget(globals()["self.pushButton_"+str(key)])
				spacerItem = QSpacerItem(40, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
				globals()["self.horizontalLayout_" + str(cu_hl) + str(i)].addItem(spacerItem)
			
				
				# Create and Add Column (1 for each button)
				globals()["self.tab_"+str(key)] = QWidget()
				globals()["self.tab_"+str(key)].setObjectName("tab_{}".format(key))
				globals()["self.horizontalLayout_" + str(j)] = QHBoxLayout(globals()["self.tab_"+str(key)])
				globals()["self.horizontalLayout_" + str(j)].setObjectName("horizontalLayout_{}".format(str(j)))	

				globals()["self.columnView_"+str(key)] = QColumnView(globals()["self.tab_"+str(key)])
				globals()["self.columnView_"+str(key)].setMinimumSize(QSize(0, 0))
				globals()["self.columnView_"+str(key)].setObjectName("columnView_{}".format(str(key)))
				globals()["self.horizontalLayout_" + str(j)].addWidget(globals()["self.columnView_"+str(key)])
				self.stackedWidget.addWidget(globals()["self.tab_"+str(key)])

				# Create signal and connect it to the slot self.displayColumn
				globals()["self.pushButton_"+str(key)].pressed.connect(lambda val=key: self.displayColumn(val))
				# Static configuration for columnView object
				globals()["self.columnView_"+str(key)].setModel(self.model)
				globals()["self.columnView_"+str(key)].setRootIndex(self.model.index(value))
				# Create signal and connect it to slot
				globals()["self.columnView_"+str(key)].clicked.connect(self.displayPath)
				# Create action from menunar
				# self.actionOpen_file.clicked.connect(self.openConfigFile)


			
			# Manage button position by adding spaces if number of button < 10
			for i_space in range(nb_button_add_line, (max_button+2), 1):
				spacerItem = QSpacerItem(40, 20, QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
				globals()["self.horizontalLayout_" + str(cu_hl) + str(i)].addItem(spacerItem)
				
			globals()["self.horizontalLayout_" + str(j)].setStretch(31, 10)
			for i_hl in range(0, nb_horizLayout, 1):
				self.verticalLayout_2.insertLayout(k, globals()["self.horizontalLayout_" + str(i_hl) + str(i)])
				k += 1
				# #print("insert self.horizontalLayout_{}{} at position {}".format(i_hl, i, k))
			
			
			# #print("k = {}".format(k))
			self.line = QFrame(self.centralWidget)
			# self.line.setLineWidth(3)
			self.line.setFrameShape(QFrame.Shape.HLine)
			self.line.setFrameShadow(QFrame.Shadow.Sunken)
			self.line.setObjectName("line")
			self.verticalLayout_2.insertWidget(k, self.line)
			# #print("insert line at position {}".format(k))
			k += 1
			

		self.verticalLayout_2.insertWidget(k, self.stackedWidget)
		# #print("insert Widget stacked to verticalLayout position 7")			



	def displayColumn(self, button):
		self.stackedWidget.setCurrentWidget(globals()["self.tab_"+ str(button)])



	def displayPath(self,  index):
		indexItem = self.model.index(index.row(), 0, index.parent())
		filePath = self.model.filePath(indexItem)
		self.lineEdit_CMD.setText(filePath)

	def on_pushButton_GOTO_pressed(self):
		self.lineEdit_FROM.setText(self.lineEdit_CMD.displayText())

	def on_pushButton_ADD_pressed(self):
		current_text = self.lineEdit_TERM
		new_text = "{} {}".format(current_text.displayText(), self.lineEdit_CMD.displayText())
		self.lineEdit_TERM.setText(new_text)


	def on_pushButton_CLEAR_pressed(self):
		self.lineEdit_TERM.clear()
		self.lineEdit_TERM.setText(">")


	
	def on_pushButton_HOME_pressed(self):
		self.lineEdit_FROM.setText("${HOME}")


	def on_pushButton_EXEC_pressed(self):
		current_cmd = self.lineEdit_TERM.displayText()
		current_cmd = current_cmd[2:]	# to remove the cosmetic charachter ">" and space
		#print(current_cmd)
		source = self.lineEdit_FROM
		platform_str = str(platform.uname())
		if re.search("Linux", platform_str):
			print("Linux platform detected")
			cmd = "xterm -fg white -bg black -e \'cd {}; {};read\'".format(source.displayText(), current_cmd)       
			subprocess.Popen(shlex.split(cmd))
		elif re.search("Darwin", platform_str):
			import appscript
			print("MacOS platform detected")
			print(current_cmd)
			appscript.app('Terminal').do_script(current_cmd)


		else:
			print(platform_str)
			print("I don't recognise this platform")


	def openConfigFile(self):
		print("Open config file")
		cmd = "open {}".format(self.config_file)
		os.system(cmd)
		

	  
