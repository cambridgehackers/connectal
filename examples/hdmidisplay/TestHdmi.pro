QT       += core gui

TARGET = Hdmi
TEMPLATE = app

bozoo.commands = make -f Makefile-jni objects
QMAKE_EXTRA_TARGETS += bozoo
PRE_TARGETDEPS += bozoo

HEADERS += \
    worker.h \
    #

SOURCES += \
    testhdmiqt.cpp \
    #

OBJECTS += \
    #subproj/bozo.o \
    #
