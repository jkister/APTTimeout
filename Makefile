include theos/makefiles/common.mk

TARGET = iphone:clang:8.1:4.0
export ARCHS = armv7 arm64
export SDKVERSION=8.1


BUNDLE_NAME = APTTimeout
APTTimeout_FILES = APTTimeout.mm
APTTimeout_INSTALL_PATH = /Library/PreferenceBundles
APTTimeout_FRAMEWORKS = UIKit
APTTimeout_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk


internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/APTTimeout.plist$(ECHO_END)
