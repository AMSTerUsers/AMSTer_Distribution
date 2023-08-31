#!/opt/local/bin/python
# This script create the MasTer Toolbox Organizer. 
# The widget creation are static in this script.
#
#
# Dependencies:
#	- pyqt6 python package
#
# New in Distro V 1.0:		-

#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
#
# Mja (c) 2022/10/05 - 
#-----------------------------------------------------------------------------------------------------


import re, os, subprocess
from PyQt6 import QtCore, QtGui, QtWidgets

script_path = os.path.realpath(__file__)
script_dir = os.path.dirname(script_path)
config_file = "{}/config.txt".format(script_dir)
button_l1 = {}
button_l2 = {}
button_l3 = {}

def configButton(dico, num):
	with open(config_file,  'r') as f:
		line_number = str(num)
		lines = f.readlines()
		i = 0
		for line in lines:
			if re.search(r"^"+line_number+r"_.*(\s|\t)*#{1}", line):
				target = re.search(r"^"+line_number+r"_.*(\s|\t)*#{1}", line)[0]
				if re.search(target , line):
					target = target[2:]
					target = re.search(r"\w*", target)[0]
					if target == "SPACE":
						i += 1
						target = "{}_{}".format(target, i)
						dico[target] = ""
						continue
					try:
						path_target = re.split(r"#", line)[1]
						path_target = path_target.strip() # remove spaces
						path_target = subprocess.Popen("echo {}".format(path_target), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()
						path_target = path_target[0].decode('ascii')
						path_target = re.search(r"/.*\w$", path_target)[0]	# Keep only first line and remove carriage return
						dico[target] = path_target
					except:
						continue


def readParam(param):
	with open(config_file,  'r') as f:
		lines = f.readlines()
		for line in lines:
			if re.search(param, line):
				target = int(re.split("#", line)[0])
				return target

configButton(button_l1, 1)
configButton(button_l2, 2)
configButton(button_l3, 3)
max_button = readParam("MAX_BUTTON")
# print(button_l1)
# print(button_l2)
# print(button_l3)




class Ui_MainWindow(object):
	def setupUi(self, MainWindow):
		MainWindow.setObjectName("MainWindow")
		MainWindow.resize(1099, 946)
		self.centralWidget = QtWidgets.QWidget(MainWindow)
		self.max_button = max_button
		self.config_file = config_file
		self.menuBar = QtWidgets.QMenuBar(MainWindow)
		self.menuBar.setGeometry(QtCore.QRect(0, 0, 1099, 21))
		self.menuBar.setObjectName("menuBar")
		self.menuConfiguration = QtWidgets.QMenu(self.menuBar)
		self.menuConfiguration.setObjectName("menuConfiguration")
		MainWindow.setMenuBar(self.menuBar)
		self.actionOpen_file = QtGui.QAction(MainWindow)
		self.actionOpen_file.setObjectName("actionOpen_file")
		self.menuConfiguration.addAction(self.actionOpen_file)
		self.menuBar.addAction(self.menuConfiguration.menuAction())


		self.centralWidget.setObjectName("centralWidget")
		self.verticalLayout_2 = QtWidgets.QVBoxLayout(self.centralWidget)
		self.verticalLayout_2.setObjectName("verticalLayout_2")
		self.verticalLayout_2.setSpacing(2)
	

	
		
		self.stackedWidget = QtWidgets.QStackedWidget(self.centralWidget)
		self.stackedWidget.setObjectName("stackedWidget")


	
		self.horizontalLayout_5 = QtWidgets.QHBoxLayout()
		self.horizontalLayout_5.setContentsMargins(10, 5, 10, 5)
		self.horizontalLayout_5.setSpacing(30)
		self.horizontalLayout_5.setObjectName("horizontalLayout_5")		
		self.label_FROM = QtWidgets.QLabel(self.centralWidget)
		self.label_FROM.setObjectName("label_FROM")
		self.horizontalLayout_5.addWidget(self.label_FROM)
		self.lineEdit_FROM = QtWidgets.QLineEdit(self.centralWidget)
		self.lineEdit_FROM.setObjectName("lineEdit_FROM")
		self.horizontalLayout_5.addWidget(self.lineEdit_FROM)
		self.pushButton_GOTO = QtWidgets.QPushButton(self.centralWidget)
		self.pushButton_GOTO.setMinimumSize(QtCore.QSize(60, 35))
		self.pushButton_GOTO.setObjectName("pushButton_GOTO")
		self.horizontalLayout_5.addWidget(self.pushButton_GOTO)
		self.pushButton_HOME = QtWidgets.QPushButton(self.centralWidget)
		self.pushButton_HOME.setMinimumSize(QtCore.QSize(60, 35))
		self.pushButton_HOME.setObjectName("pushButton_HOME")
		self.horizontalLayout_5.addWidget(self.pushButton_HOME)
		self.verticalLayout_2.addLayout(self.horizontalLayout_5)
		# print("add horizontalLayout_5 to verticalLayout")


		self.line = QtWidgets.QFrame(self.centralWidget)
		self.line.setFrameShape(QtWidgets.QFrame.Shape.HLine)
		self.line.setFrameShadow(QtWidgets.QFrame.Shadow.Sunken)
		self.line.setObjectName("line")
		self.verticalLayout_2.addWidget(self.line)

		
		self.horizontalLayout_6 = QtWidgets.QHBoxLayout()
		self.horizontalLayout_6.setContentsMargins(10, 5, 10, 5)
		self.horizontalLayout_6.setSpacing(30)
		self.horizontalLayout_6.setObjectName("horizontalLayout_6")
		self.label_CMD = QtWidgets.QLabel(self.centralWidget)
		self.label_CMD.setObjectName("label_CMD")
		self.horizontalLayout_6.addWidget(self.label_CMD)
		self.lineEdit_CMD = QtWidgets.QLineEdit(self.centralWidget)
		self.lineEdit_CMD.setClearButtonEnabled(False)
		self.lineEdit_CMD.setAlignment(QtCore.Qt.AlignmentFlag.AlignLeading|QtCore.Qt.AlignmentFlag.AlignLeft|QtCore.Qt.AlignmentFlag.AlignTop)      
		self.lineEdit_CMD.setObjectName("lineEdit_CMD")
		self.horizontalLayout_6.addWidget(self.lineEdit_CMD)
		self.pushButton_ADD = QtWidgets.QPushButton(self.centralWidget)
		self.pushButton_ADD.setMinimumSize(QtCore.QSize(60, 35))
		self.pushButton_ADD.setObjectName("pushButton_ADD")
		self.horizontalLayout_6.addWidget(self.pushButton_ADD)
		self.verticalLayout_2.addLayout(self.horizontalLayout_6)
		# print("add horizontalLayout_6 to verticalLayout")

		self.line = QtWidgets.QFrame(self.centralWidget)
		self.line.setFrameShape(QtWidgets.QFrame.Shape.HLine)
		self.line.setFrameShadow(QtWidgets.QFrame.Shadow.Sunken)
		self.line.setObjectName("line")
		self.verticalLayout_2.addWidget(self.line)

		self.horizontalLayout_7 = QtWidgets.QHBoxLayout()
		self.horizontalLayout_7.setContentsMargins(10, 5, 10, 5)
		self.horizontalLayout_7.setSpacing(30)
		self.horizontalLayout_7.setObjectName("horizontalLayout_7")
		self.lineEdit_TERM = QtWidgets.QLineEdit(self.centralWidget)
		self.lineEdit_TERM.setMinimumSize(QtCore.QSize(0, 80))
		self.lineEdit_TERM.setObjectName("lineEdit_TERM")
		self.horizontalLayout_7.addWidget(self.lineEdit_TERM)
		self.verticalLayout = QtWidgets.QVBoxLayout()
		self.verticalLayout.setSpacing(0)
		self.verticalLayout.setObjectName("verticalLayout")
		self.pushButton_EXEC = QtWidgets.QPushButton(self.centralWidget)
		self.pushButton_EXEC.setMinimumSize(QtCore.QSize(60, 35))
		self.pushButton_EXEC.setObjectName("pushButton_EXEC")
		self.verticalLayout.addWidget(self.pushButton_EXEC)
		spacerItem12 = QtWidgets.QSpacerItem(20, 20, QtWidgets.QSizePolicy.Policy.Minimum, QtWidgets.QSizePolicy.Policy.Preferred)
		self.verticalLayout.addItem(spacerItem12)
		self.pushButton_CLEAR = QtWidgets.QPushButton(self.centralWidget)
		self.pushButton_CLEAR.setMinimumSize(QtCore.QSize(60, 35))
		self.pushButton_CLEAR.setObjectName("pushButton_CLEAR")
		self.verticalLayout.addWidget(self.pushButton_CLEAR)
		self.horizontalLayout_7.addLayout(self.verticalLayout)
		self.verticalLayout_2.addLayout(self.horizontalLayout_7)
		# print("add horizontalLayout_7 to verticalLayout")
		MainWindow.setCentralWidget(self.centralWidget)

		self.retranslateUi(MainWindow)
		QtCore.QMetaObject.connectSlotsByName(MainWindow)

	def retranslateUi(self, MainWindow):
		_translate = QtCore.QCoreApplication.translate
		MainWindow.setWindowTitle(_translate("MainWindow", "MainWindow"))

		self.pushButton_GOTO.setText(_translate("MainWindow", "GOTO"))
		self.pushButton_HOME.setText(_translate("MainWindow", "HOME"))
		self.pushButton_ADD.setText(_translate("MainWindow", "ADD"))
		self.label_FROM.setText(_translate("MainWindow", "Go To Dir Where To Run"))
		self.label_CMD.setText(_translate("MainWindow", "Select Command/Param To Run"))
		self.lineEdit_CMD.setText(_translate("MainWindow", ""))
		self.lineEdit_FROM.setText(_translate("MainWindow", "${HOME}"))
		self.lineEdit_TERM.setText(_translate("MainWindow", ">"))
		self.pushButton_EXEC.setText(_translate("MainWindow", "EXEC"))
		self.pushButton_CLEAR.setText(_translate("MainWindow", "CLEAR"))
		self.menuConfiguration.setTitle(_translate("MainWindow", "Configuration"))
		self.actionOpen_file.setText(_translate("MainWindow", "Open file"))


if __name__ == "__main__":
    import sys
    app = QtWidgets.QApplication(sys.argv)
    MainWindow = QtWidgets.QMainWindow()
    ui = Ui_MainWindow()
    ui.setupUi(MainWindow)
    MainWindow.show()
    sys.exit(app.exec())
