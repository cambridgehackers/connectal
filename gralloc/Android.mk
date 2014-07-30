LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_SHARED_LIBRARIES := libcutils liblog

HDMI_SRC_FILES = DmaConfigProxy.cpp DmaIndicationWrapper.cpp HdmiDisplayRequestProxy.cpp HdmiDisplayIndicationWrapper.cpp HdmiInternalRequestProxy.cpp HdmiInternalIndicationWrapper.cpp

LOCAL_SRC_FILES := 	\
	../cpp/portal.cpp ../cpp/dmaManager.cpp \
	$(addprefix ../examples/hdmidisplay/zedboard/jni/, $(HDMI_SRC_FILES)) \
	 gralloc.cpp mapper.cpp

LOCAL_MODULE_TAGS = optional
LOCAL_MODULE := gralloc.portal
LOCAL_CFLAGS:= -DZYNQ -DLOG_TAG=\"gralloc\" -I$(LOCAL_PATH)/../cpp -I$(LOCAL_PATH)/../lib/cpp -I$(LOCAL_PATH)/.. -I$(LOCAL_PATH)/../examples/hdmidisplay/zedboard/jni -I$(LOCAL_PATH)/../drivers/zynqportal

include $(BUILD_SHARED_LIBRARY)
