
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_ARM_MODE := arm
LOCAL_MODULE := timelimit
LOCAL_SRC_FILES := timelimit.c
LOCAL_MODULE_TAGS := optional
LOCAL_CFLAGS := "-DHAVE_ERRNO_H -march=armv7-a"

include $(BUILD_EXECUTABLE)
