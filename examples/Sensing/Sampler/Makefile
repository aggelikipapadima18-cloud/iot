COMPONENT=SensingPeriodicSamplerAppC
SENSOR_DIR ?= tmote_onboard_sensors
CFLAGS += -I.. -I../sampleLog
CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -I.. -I../$(SENSOR_DIR)
CFLAGS += -DCC1K_DEFAULT_FREQ=CC1K_914_077_MHZ

TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
