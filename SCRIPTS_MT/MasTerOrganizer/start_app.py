#!/opt/local/bin/python

# http://livre21.com/LIVREF/F6/F006059.pdf
# 
# Contro Panel created with eric7 software and Qt Designer (both free)
# Documentation from http://livre21.com/LIVREF/F6/F006059.pdf
#
# Purpose: Getting faster in 'hot' directory in a column view file explorer.
# 
#	Package Requirements:
#		PyQt6 		--> python -m pip install pyqt6 
# 		appscript 	--> python -m pip install appscript (for MacOS only)
#
#	Files:
#		Ui_main_window_man.py : (contain mainly the objetcs declaration and graphical structure of widgets in the window)
#		main_window.py : (contain the action/events/method and declaration of objects in dynamics for which the number may vary)
#		config.txt : Config file in same directory of these scripts with the syntax in place
#
#
# New in Distro V 1.0:		-
#				V 2.0: If Linux system, call function to read current display and export relative $DISPLAY variable
#
#
# By Maxime Jaspard, 2022-09-30
#-------------------------------------------------------------------------------------------------------------------

import sys




from PyQt6.QtWidgets import QApplication
import main_window
app = QApplication(sys.argv)


if len(sys.argv) != 1:	
	display_number = sys.argv[1]
	main_window.setupScreen(display_number)
	
	
mainWindow = main_window.MainWindow()

# print(mainWindow.__dict__)

mainWindow.show()

rc = app.exec()

sys.exit(rc)
