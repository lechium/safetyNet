CC = $(shell xcrun -l -f clang)
SYSROOT = $(shell xcrun -l --sdk appletvos --show-sdk-path)

INCLUDES = -I. -I$(SYSROOT)/usr/include -Iinclude -F.
CFLAGS = $(INCLUDES) -fobjc-arc -arch arm64 -isysroot $(SYSROOT) -mtvos-version-min=10.0
LDFLAGS = -framework Foundation -framework MobileCoreServices -framework IOKit

BOBJ ?= build/obj

BUILD_FLD = build/usr/bin

.PHONY: all clean


OBJ = $(BOBJ)/main.o $(BOBJ)/FileMonitor.o $(BOBJ)/KBSafetyNet.o

$(BOBJ):
	mkdir -p $(BOBJ)

$(BOBJ)/%.o : %.m
	$(CC) -x objective-c -c -o $@ $< $(CFLAGS)

#$(BOBJ)/%.o : SCEvents/%.m
	#$(CC) -x objective-c -c -o $@ $< $(CFLAGS)

safetynet: $(BOBJ) $(OBJ)

	mkdir -p $(BUILD_FLD)
	echo "$(CC) $(OBJ) $(CFLAGS) $(LDFLAGS) -o $(BUILD_FLD)/safetynet"
	$(CC) $(OBJ) $(CFLAGS) $(LDFLAGS) -o $(BUILD_FLD)/safetynet
	#$(CC) $(OBJ) $(CFLAGS) $(LDFLAGS) -o safetynet
	jtool --sign platform --ent ent.plist $(BUILD_FLD)/safetynet --inplace
	rm -rf layout/usr/bin/
	mkdir -p layout/usr/bin/
	cp $(BUILD_FLD)/safetynet layout/usr/bin/



all: safetynet
clean:
	rm -rf build
